require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'
require 'pathname'

class Pipeline::Brakeman < Pipeline::BaseTask

  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Brakeman"
    @description = "Source analysis for Ruby"
    @stage = :code
    @labels << "code" << "ruby" << "rails"
  end

  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    @result=runsystem(true, "brakeman", "-q", "-f", "json", "#{rootpath}")
  end

  def analyze
    # puts @result
    begin
      parsed = JSON.parse(@result)
      parsed["warnings"].each do |warning|
        file = relative_path(warning['file'], @trigger.path)

        detail = "#{warning['message']} Link: #{warning['link']}"
        source = { :scanner => @name, :file => file, :line => warning['line'], :code => warning['code'] }

        report warning["warning_type"], detail, source, severity(warning["confidence"]), fingerprint("#{warning['message']}#{warning['link']}#{severity(warning["confidence"])}#{source}")
      end
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, "brakeman", "-v")
    if supported =~ /command not found/
      Pipeline.notify "Run: gem install brakeman"
      return false
    else
      return true
    end
  end

end

