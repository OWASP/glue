require 'pipeline/finding'

class Pipeline::BaseReporter
  attr_accessor :name, :format
 
  def initialize()
  end

  def run_report(tracker)
  	Pipeline.notify "Running base reoprt..."
  	output = ""
        tracker.findings.each do |finding|
    	  output += out(finding)
        end
        output
  end

  def out(finding)
  end

end
