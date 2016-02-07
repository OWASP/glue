require 'pipeline/tasks/base_task'
require 'pipeline/util'
# require 'nokogiri'

class Pipeline::Checkmarx < Pipeline::BaseTask
  # Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = 'Checkmarx'
    @description = 'CxSAST'
    @stage = :code
    @labels << 'code'
  end

  def run
    Pipeline.notify @name.to_s
    rootpath = @trigger.path
    runsystem(true, 'runCxConsole.sh', 'scan', '-v',
              '-CxUser', @tracker.options[:checkmarx_user].to_s,
              '-CxPassword', @tracker.options[:checkmarx_password].to_s,
              '-CxServer', @tracker.options[:checkmarx_server].to_s,
              '-LocationType', 'folder',
              '-LocationPath', rootpath.to_s,
              '-ProjectName', @tracker.options[:checkmarx_project].to_s,
              '-ReportXML', "#{rootpath}checkmarx_results.xml",
              '-Log', @tracker.options[:checkmarx_log].to_s
             )
    # @results = Nokogiri::XML(File.read("#{rootpath}checkmarx_results.xml")).xpath '//Result'
  end

  def analyze
    @results.each do |result|
      description = result.parent.attributes['name'].value.tr('_', ' ')
      detail = result.attributes['DeepLink'].value
      source = { scanner: @name, file: result.attributes['FileName'].value, line: result.attributes['Line'].value.to_i, code: result.at_xpath('Path/PathNode/Snippet/Line/Code').text }
      sev = severity(result.parent.attributes['Severity'].value)
      print = fingerprint("#{description}#{source}#{sev}")

      report description, detail, source, sev, print
    end
  rescue Exception => e
    Pipeline.warn e.message
    Pipeline.warn e.backtrace
  end

  def supported?
    supported = runsystem(true, 'runCxConsole.sh', '--help')
    if supported =~ /command not found/
      Pipeline.notify 'Install CxConsolePlugin'
      return false
    else
      return true
    end
  end
end
