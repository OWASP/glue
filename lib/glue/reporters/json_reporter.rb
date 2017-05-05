require 'glue/finding'
require 'glue/reporters/base_reporter'

require 'json'

class Glue::JSONReporter < Glue::BaseReporter

  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "JSONReporter"
    @format = :to_json
  end

  def out(finding)
    finding.to_json
  end

  def combine_reports(reports)
    '[' << reports.join(', ') << ']'
  end
end
