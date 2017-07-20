require 'glue/tasks/base_task'
require 'glue/util'
require 'nokogiri'

class Glue::Checkmarx < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Checkmarx"
    @description = "CxSAST"
    @stage = :code
    @labels << "code"
    @checkmarx_path = tracker.options[:checkmarx_path] || "runCxConsole.sh"
  end

  def run
    rootpath = @trigger.path

    # source: https://stackoverflow.com/a/2149183/4792970
    mandatory = [:checkmarx_user, :checkmarx_password, :checkmarx_server, :checkmarx_project]   
    missing = mandatory.select{ |param| @tracker.options[param].nil? }     
    unless missing.empty?                                           
      Glue.error "missing one or more required params: #{missing}"
      return
    end  

    params = [@checkmarx_path, "scan", "-v",
      "-CxUser", "#{@tracker.options[:checkmarx_user]}",
      "-CxPassword", "#{@tracker.options[:checkmarx_password]}",
      "-CxServer", "#{@tracker.options[:checkmarx_server]}",
      "-LocationType", "folder",
      "-LocationPath", "#{rootpath}",
      "-ProjectName", "#{@tracker.options[:checkmarx_project]}",
      "-ReportXML", "#{Dir.pwd}/checkmarx_results.xml",
      "-ReportPDF", "#{Dir.pwd}/checkmarx_results.pdf"]
    
    if (@tracker.options[:checkmarx_log])
      params << "-Log"
      params << "#{@tracker.options[:checkmarx_log]}"
    end

    if (@tracker.options[:checkmarx_exclude])
      params << "-LocationExclude"
      params << "#{@tracker.options[:checkmarx_exclude]}"
    end

    if (@tracker.options[:checkmarx_preset])
      params << "-Preset"
      params << "#{@tracker.options[:checkmarx_preset]}"
    end

    if (@tracker.options[:checkmarx_incremental])
      params << "-Incremental"
    end

    output = runsystem(true, *params)

    #CxConsole does not set exit code on errors, so we need to test if a report file created
    if (File.file?("checkmarx_results.xml"))
      @results = Nokogiri::XML(File.read("checkmarx_results.xml")).xpath '//Result'
    else 
      Glue.fatal "checkmarx scan failed: #{output}"
    end
  end

  def analyze
    begin
      if (@results == nil)
        return
      end
      @results.each do |result|
        description = result.parent.attributes['name'].value.gsub('_', ' ')
        detail = result.attributes['DeepLink'].value
        state = result.attributes['state'].value.to_i

        #state different from zero mean that the result is marked as ignored (not exploitable) in CxSAST web portal
        if (state > 0)
          return
        end

        source = { :scanner => @name, :file => result.attributes['FileName'].value, :line =>  result.attributes['Line'].value.to_i, :code => result.at_xpath('Path/PathNode/Snippet/Line/Code').text }
        sev = severity(result.parent.attributes['Severity'].value)
        fprint = fingerprint("#{description}#{source}#{sev}")

        report description, detail, source, sev, fprint
      end
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, @checkmarx_path, "--help")
    if supported =~ /command not found/
      Glue.notify "Install CxConsolePlugin"
      return false
    else
      return true
    end
  end

end
