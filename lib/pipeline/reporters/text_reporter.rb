require 'pipeline/finding'
require 'pipeline/reporters/base_reporter'

class Pipeline::TextReporter < Pipeline::BaseReporter
  Pipeline::Reporters.add self

  attr_accessor :name, :format

  def initialize
    @name = 'TextReporter'
    @format = :to_s
  end

  def out(finding)
    finding.to_string << "\n"
  end
end
