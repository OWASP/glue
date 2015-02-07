require 'pipeline/finding'

class Pipeline::BaseReporter
  attr_accessor :name, :format
 
  def initialize()
  end

  def run_report(tracker)
  end

end
