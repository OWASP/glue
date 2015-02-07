require 'pipeline/tasks/base_task'
require 'json'

class Pipeline::Brakeman < Pipeline::BaseTask
  
  Pipeline::Tasks.add self
  
  def initialize(trigger)
    super(trigger)
    @name = "Brakeman"
    @description = "Source analysis for Ruby"
    @stage = :code
    @labels << "code" << "rails"
  end
  
  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    @result=`brakeman -q -f json "#{rootpath}"`
  end

  def analyze
    # puts @result
    begin
      parsed = JSON.parse(@result)
      parsed["warnings"].each do |warning|
        detail = "Message: #{warning['message']} Link: #{warning['link']}"
        source = "File: #{warning['file']} Line: #{warning['line']} Code: #{warning['code']}"
        report warning["warning_type"], detail, source, warning["confidence"] 
      end
    rescue
      Pipeline.notify "Appears not to be a rails project ... brakeman skipped."
    end
  end

  def supported?
    supported=`brakeman -v`
    if supported =~ /command not found/
      return false
    else
      return true
    end
  end

end

