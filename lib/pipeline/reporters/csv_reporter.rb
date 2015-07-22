require 'pipeline/finding'
require 'pipeline/reporters/base_reporter'

class Pipeline::CSVReporter < Pipeline::BaseReporter

  Pipeline::Reporters.add self

  attr_accessor :name
 
  def initialize()
    @name = "CSVReporter"  
    @format = :to_csv
  end
  
  def out(finding)
    finding.to_csv
  end

end
