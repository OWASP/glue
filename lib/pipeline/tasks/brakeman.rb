require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'

class Pipeline::Brakeman < Pipeline::BaseTask
  
  Pipeline::Tasks.add self
  include Pipeline::Util
  
  def initialize(trigger)
    super(trigger)
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
        detail = "Message: #{warning['message']} Link: #{warning['link']}"
        source = "#{@name} File: #{warning['file']} Line: #{warning['line']} Code: #{warning['code']}"
        report warning["warning_type"], detail, source, warning["confidence"], warning['fingerprint']
      end
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.notify "Appears not to be a rails project ... brakeman skipped."
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

