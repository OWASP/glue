require 'pipeline/finding'
require 'pipeline/reporters/base_reporter'

require 'json'

class Pipeline::JSONReporter < Pipeline::BaseReporter

  Pipeline::Reporters.add self

  attr_accessor :name, :format
 
  def initialize()
    @name = "JSONReporter"    
    @format = :to_json
  end

  def out(finding)
    finding.to_json
  end
end
