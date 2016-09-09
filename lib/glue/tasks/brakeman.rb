require 'glue/tasks/base_task'
require 'json'
require 'glue/util'
require 'pathname'

class Glue::Brakeman < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Brakeman"
    @description = "Source analysis for Ruby"
    @stage = :code
    @labels << "code" << "ruby" << "rails"
  end

  def run
    rootpath = @trigger.path
    @result=runsystem(true, "brakeman", "-A", "-q", "-f", "json", "#{rootpath}")
  end

  def analyze
    # puts @result
    begin
      parsed = JSON.parse(@result)
      parsed["warnings"].each do |warning|
        file = relative_path(warning['file'], @trigger.path)

        detail = "#{warning['message']}\n#{warning['link']}"
        if ! warning['line']
          warning['line'] = "0"
        end
        if ! warning['code']
          warning['code'] = ""
        end
        source = { :scanner => @name, :file => file, :line => warning['line'], :code => warning['code'].lstrip }

        report warning["warning_type"], detail, source, severity(warning["confidence"]), fingerprint("#{warning['message']}#{warning['link']}#{severity(warning["confidence"])}#{source}")
      end
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, "brakeman", "-v")
    if supported =~ /command not found/
      Glue.notify "Run: gem install brakeman"
      return false
    else
      return true
    end
  end

end
