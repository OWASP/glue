require 'glue/tasks/base_task'

class Glue::ScanJS < Glue::BaseTask

#  WIP
#  Glue::Tasks.add self

  def initialize(trigger, tracker)
  	super(trigger)
    @name = "ScanJS"
    @description = "Source analysis for JavaScript"
    @stage = :code
    @labels << "code" << "javascript"
  end

  def run
    Glue.notify "#{@name}"
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
