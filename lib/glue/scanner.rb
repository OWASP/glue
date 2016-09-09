require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'

class Glue::Scanner
  attr_reader :tracker
  attr_reader :mounter

  #Pass in path to the root of the Rails application
  def initialize
    @stage = :wait
    @stages = [ :wait, :mount, :file, :code, :live, :done]
  end

  #Process everything in the Rails application
  def process target, tracker
    @stages.each do |stage|
      Glue.notify "Running tasks in stage: #{stage}"
      @stage = stage
      begin
         Glue::Tasks.run_tasks(target, stage, tracker)
      rescue Exception => e
        Glue.warn e.message
        raise e
      end
    end
  end
end
