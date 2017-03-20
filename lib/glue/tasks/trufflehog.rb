require 'glue/tasks/base_task'
require 'glue/util'
require 'httparty'

# Runs the TruffleHog scanner. See https://github.com/dxa4481/truffleHog for details.
class Glue::Trufflehog < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  HEX_CHARS = "1234567890abcdefABCDEF"

  ISSUE_SEVERITY = 4

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Trufflehog"
    @description = "Runs Trufflehog check"
    @stage = :code
    @labels << "code" << "java" << ".net"

    @trufflehog_path = '/home/glue/tools/truffleHog/truffleHog/truffleHog.py'
  end

  def run
    Glue.notify "#{@name}"
    @result = runsystem(true, '/usr/bin/env', 'python', @trufflehog_path, '--json', @trigger.path)
  end

  def report_stale_lib(app_id, lib)
    # report description, detail, source, severity, fingerprint
    self.report "#{lib['file_name']} is out of date.", 
        "Project uses version #{lib['file_version']}, #{LIB_STALE_CONNECTOR} #{lib['latest_version']}. #{contrast_library_html_url(app_id, lib['hash'])}",
        lib['file_name'],
        'NOTE',
        lib['hash']
  end

  def report_vulnerable_lib(app_id, lib)
    vuln_count = lib['total_vulnerabilities']
    self.report "#{lib['file_name']} has #{vuln_count} known security #{vuln_count > 1 ? 'vulnerabilities' : 'vulnerability'}.",
        "#{lib['file_name']} #{LIB_RATING_CONNECTOR} #{lib['grade']}. #{contrast_library_html_url(app_id, lib['hash'])}",
        lib['file_name'],
        'High',
        lib['hash']
  end

  def report_trace(app_id, trace)
    Glue.debug "Reporting trace with fingerprint #{contrast_trace_html_url(app_id, trace['uuid'])}"
    self.report trace['title'], contrast_trace_html_url(app_id, trace['uuid']), trace['uuid'], trace['severity'], trace['uuid']
  end

  def analyze
    begin
      Glue.debug "Parsing results..."
      puts @result
      get_warnings
    rescue Exception => e
      Glue.notify "Problem running Trufflehog ... skipped."
      Glue.notify e.message
      raise e
    end
  end

  def supported?
    true
  end

  def get_warnings
    JSON::parse(@result).each do |title, string|
      description = "Possible password or other secret at #{title}."
      detail = "Apparent password or other secret: #{string}"
      fingerprint = "Trufflehog|#{title}"
      self.report "Possible password or other secret in source code.", detail, title, ISSUE_SEVERITY, fingerprint
    end
  end
end
