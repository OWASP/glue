require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'
require 'pathname'

class Pipeline::Brakeman < Pipeline::BaseTask
  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = 'Brakeman'
    @description = 'Source analysis for Ruby'
    @stage = :code
    @labels << 'code' << 'ruby' << 'rails'
  end

  def run
    # Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    @result = runsystem(true, 'brakeman', '-A', '-q', '-f', 'json', rootpath.to_s)
  end

  def analyze
    # puts @result

    parsed = JSON.parse(@result)
    parsed['warnings'].each do |warning|
      file = relative_path(warning['file'], @trigger.path)

      detail = "#{warning['message']}\n#{warning['link']}"
      warning['line'] = '0' unless warning['line']
      warning['code'] = '' unless warning['code']
      source = { scanner: @name, file: file, line: warning['line'], code: warning['code'].lstrip }

      report warning['warning_type'], detail, source, severity(warning['confidence']), fingerprint("#{warning['message']}#{warning['link']}#{severity(warning['confidence'])}#{source}")
    end
  rescue Exception => e
    Pipeline.warn e.message
    Pipeline.warn e.backtrace
  end

  def supported?
    supported = runsystem(true, 'brakeman', '-v')
    if supported =~ /command not found/
      Pipeline.notify 'Run: gem install brakeman'
      return false
    else
      return true
    end
  end
end
