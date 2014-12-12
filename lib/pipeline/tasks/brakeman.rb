require 'pipeline/tasks/base_task'

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
    # TODO:  Process JSON
  end

  def supported?
  	# In future, verify tool is available.
  	return true 
  end

end

