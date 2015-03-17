require 'pipeline/tasks/base_task'

class Pipeline::ScanJS < Pipeline::BaseTask
  
#  WIP  
#  Pipeline::Tasks.add self
  
  def initialize(trigger)
  	super(trigger)
    @name = "ScanJS"
    @description = "Source analysis for JavaScript"
    @stage = :code
    @labels << "code" << "javascript"
  end

  def run
    Pipeline.notify "#{@name}"
  	rootpath = @trigger.path
	  @result=`scanner.js -t "#{rootpath}"`
  end

  def analyze
    puts @result
  end

  def supported?
  	# In future, verify tool is available.
  	return true 
  end

end

