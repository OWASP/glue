require 'pipeline/event'
require 'pipeline/tracker'
require 'pipeline/tasks'

class Pipeline::Scanner
  attr_reader :tracker
  attr_reader :mounter

  # Pass in path to the root of the Rails application
  def initialize
    @stage = :wait
    @stages = [:wait, :mount, :file, :code, :live, :done]
  end

  # Process everything in the Rails application
  def process(target, tracker)
    @stages.each do |stage|
      Pipeline.notify "Running tasks in stage: #{stage}"
      @stage = stage
      begin
        Pipeline::Tasks.run_tasks(target, stage, tracker)
      rescue Exception => e
        Pipeline.warn e.message
        raise e
      end
    end
  end
end
