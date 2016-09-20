require 'glue/finding'

class Glue::BaseReporter
  attr_accessor :name, :format

  def initialize()
  end

  def run_report(tracker)
  	Glue.notify "Running base report..."
  	output = ""
    tracker.findings.each do |finding|
      output << out(finding)
    end
    output
  end

  def out(finding)
  end

end
