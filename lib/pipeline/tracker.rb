class Pipeline::Tracker
  attr_reader :options
  attr_reader :warnings
  attr_reader :errors
  attr_reader :findings

  #Pass in path to the root of the Rails application
  def initialize options
    @options = options
    @warnings = []
    @errors = []
    @findings = []
  end

  #Process events that
  def process event

  end

  def error error
    @errors << error
  end

  def warn warning
    @warnings << warning
  end

  def report finding
    @findings << finding
  end  
end
