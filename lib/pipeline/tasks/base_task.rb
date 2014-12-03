require 'pipeline/finding'

class Pipeline::BaseTask
  attr_reader :findings, :warnings, :trigger
  attr_accessor :name
  attr_accessor :description
  attr_accessor :stage

  def initialize(trigger)
    @findings = []
    @warnings = []
    @trigger = trigger
  end

  def report finding
    @findings << finding
  end

  def warn warning
    @warnings << warning
  end

  def name
    @name
  end

  def description
    @description
  end

  def stage
    @stage
  end


  def run
  end

  def analyze
  end

  def supported?
  end

end
