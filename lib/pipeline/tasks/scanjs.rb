require 'pipeline/tasks/base_task'

class Pipeline::ScanJS < Pipeline::BaseTask
  #  WIP
  #  Pipeline::Tasks.add self

  def initialize(trigger, _tracker)
    super(trigger)
    @name = 'ScanJS'
    @description = 'Source analysis for JavaScript'
    @stage = :code
    @labels << 'code' << 'javascript'
  end

  def run
    Pipeline.notify @name.to_s
    rootpath = @trigger.path
    @result = `scanner.js -t "#{rootpath}"`
  end

  def analyze
    puts @result
  end

  def supported?
    # In future, verify tool is available.
    true
  end
end
