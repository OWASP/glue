require 'glue/finding'

class Glue::BaseReporter
  attr_accessor :name, :format

  def initialize()
  end

  def run_report(tracker)
  	Glue.notify "Running base report..."
    reports = [ ]
    tracker.findings.each do |finding|
      reports << out(finding)
    end

    combine_reports(reports)
  end

  def out(finding)
  end

  def combine_reports(reports)
    reports.join
  end
end
