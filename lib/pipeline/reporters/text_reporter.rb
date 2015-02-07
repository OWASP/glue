require 'pipeline/finding'
require 'pipeline/reporters/base_reporter'

class Pipeline::TextReporter < Pipeline::BaseReporter

  Pipeline::Reporters.add self

  attr_accessor :name
 
  def initialize()
    @name = "TextReporter"  
    @format = :text
  end

  def run_report(tracker)
    tracker.findings.each do |finding|
      puts finding.to_string
    end
  end

end
