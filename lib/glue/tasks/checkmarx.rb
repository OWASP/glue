require 'glue/tasks/base_task'
require 'glue/util'
require 'nokogiri'

class Glue::Checkmarx < Glue::BaseTask

  # Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Checkmarx"
    @description = "CxSAST"
    @stage = :code
    @labels << "code"
  end

  def run
    rootpath = @trigger.path
    runsystem(true, "runCxConsole.sh", "scan", "-v",
      "-CxUser", "#{@tracker.options[:checkmarx_user]}",
      "-CxPassword", "#{@tracker.options[:checkmarx_password]}",
      "-CxServer", "#{@tracker.options[:checkmarx_server]}",
      "-LocationType", "folder",
      "-LocationPath", "#{rootpath}",
      "-ProjectName", "#{@tracker.options[:checkmarx_project]}",
      "-ReportXML", "#{rootpath}checkmarx_results.xml",
      "-Log", "#{@tracker.options[:checkmarx_log]}"
    )
    @results = Nokogiri::XML(File.read("#{rootpath}checkmarx_results.xml")).xpath '//Result'
  end

  def analyze
    begin
      @results.each do |result|
        description = result.parent.attributes['name'].value.gsub('_', ' ')
        detail = result.attributes['DeepLink'].value
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
    supported=runsystem(true, "runCxConsole.sh", "--help")
    if supported =~ /command not found/
      Glue.notify "Install CxConsolePlugin"
      return false
    else
      return true
    end
  end

end
