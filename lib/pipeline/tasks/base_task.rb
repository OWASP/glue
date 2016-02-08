require 'pipeline/finding'
require 'set'
require 'digest'

class Pipeline::BaseTask
  attr_reader :findings, :warnings, :trigger, :labels
  attr_accessor :name
  attr_accessor :description
  attr_accessor :stage
  attr_accessor :appname

  def initialize(trigger, tracker)
    @findings = []
    @warnings = []
    @labels = Set.new
    @trigger = trigger
    @tracker = tracker
    @severity_filter = {
      low: %w(low weak),
      medium: %w(medium med average),
      high: %w(high severe critical)
    }
  end

  def report(description, detail, source, severity, fingerprint)
    finding = Pipeline::Finding.new(@trigger.appname, description, detail, source, severity, fingerprint)
    @findings << finding
  end

  def warn(warning)
    @warnings << warning
  end

  def run
  end

  def analyze
  end

  def supported?
  end

  def severity(sev)
    sev = '' if sev.nil?
    return 1 if @severity_filter[:low].include?(sev.strip.chomp.downcase)
    return 2 if @severity_filter[:medium].include?(sev.strip.chomp.downcase)
    return 3 if @severity_filter[:high].include?(sev.strip.chomp.downcase)
    0
  end
end
