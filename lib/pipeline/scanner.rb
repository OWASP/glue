require 'pipeline/event'
require 'pipeline/tracker'
require 'pipeline/tasks'
require 'pipeline/mounter'

class Pipeline::Scanner
  attr_reader :options
  attr_reader :tracker
  attr_reader :mounter

  #Pass in path to the root of the Rails application
  def initialize options
    @options = options
    @mounter = Pipeline::Mounter.new(options[:target])
    @stage = :wait
    @stages = [ :wait, :mount, :file, :code, :live, :done]
  end

  #Process everything in the Rails application
  def process tracker
    path = @mounter.mount
    @stages.each do |stage|
      Pipeline.notify "Running tasks in stage: #{stage}"
      @stage = stage

      # Do work.
      Pipeline::Tasks.run_tasks(path, stage, tracker)

     end
  end
end
