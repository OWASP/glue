require 'glue/finding'
require 'glue/reporters/base_reporter'

require 'json'

# See:  https://github.com/OWASP/off
class Glue::OFFReporter < Glue::BaseReporter

  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "OFFReporter"
    @format = :to_off
  end

  def out(finding)
    finding.to_off
  end

  def combine_reports(reports)
    '[' << reports.join(', ') << ']'
  end
end
