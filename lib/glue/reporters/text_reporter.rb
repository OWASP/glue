require 'glue/finding'
require 'glue/reporters/base_reporter'

class Glue::TextReporter < Glue::BaseReporter

  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "TextReporter"
    @format = :to_s
  end

  def out(finding)
    finding.to_string << "\n"
  end

end
