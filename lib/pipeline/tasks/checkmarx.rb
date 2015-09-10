require 'pipeline/tasks/base_task'
require 'pipeline/util'
require 'nokogiri'

class Pipeline::Checkmarx < Pipeline::BaseTask

  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Checkmarx"
    @description = "CxSAST"
    @stage = :code
    @labels << "code"
  end

  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    runsystem(true, "/usr/local/bin/runCxConsole.sh", "scan", "-v",
      "-CxUser", "#{@tracker.options[:checkmarx_user]}",
      "-CxPassword", "#{@tracker.options[:checkmarx_password]}",
      "-CxServer", "#{@tracker.options[:checkmarx_server]}",
      "-LocationType", "folder",
      "-LocationPath", "#{rootpath}",
      "-ProjectName", "\"CxServer\\SP\\Groupon\\Users\\#{@tracker.options[:appname]}\"",
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
        print = fingerprint("#{description}#{source}#{sev}")

        report description, detail, source, sev, print
      end
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, "runCxConsole.sh", "--help")
    if supported =~ /command not found/
      Pipeline.notify "Install CxConsolePlugin"
      return false
    else
      return true
    end
  end

end

