require 'glue/filters/base_filter'
require 'jira-ruby'

class Glue::ContrastSeverityFilter < Glue::BaseFilter

  Glue::Filters.add self

  SEVERITIES = {
    'NOTE' => 1,
    'LOW' => 2,
    'MEDIUM' => 3,
    'HIGH' => 4,
    'CRITICAL' => 5
  }

  def initialize
    @name = "Contrast Severity Filter"
    @description = "Checks that each issue meets a minimum specified threshold (when specified)."
    @format = :to_jira
  end

  def filter tracker
    Glue.debug "Starting Contrast Severity Filter"
    Glue.debug "Minimum: #{tracker.options[:minimum_contrast_severity]}"
    if tracker.options[:minimum_contrast_severity].nil? || tracker.options[:minimum_contrast_severity].blank?
      Glue.debug "No minimum found, skipping filter."
      return  # Bail in the case where a minimum isn't specified.
    end

begin
    Glue.debug "Have #{tracker.findings.count} items pre Contrast severity filter."

    potential_findings = Array.new(tracker.findings)
    tracker.findings.clear

    minimum = tracker.options[:minimum_contrast_severity] ? SEVERITIES[tracker.options[:minimum_contrast_severity].upcase] : nil
    if minimum.nil?
      # Warn and bail if not found.
      Glue.debug "Specified minimum doesn't match any of the Contrast severities, skipping filter."
      return
    end

    #potential_findings.each { |f| Glue.debug "Checking Finding -> Task: #{f.task} | Contrast: #{contrast?(f)} | sev: #{f.severity} | below_minimum?: #{below_minimum?(f, minimum)}" }
    filtered = potential_findings.reject { |finding| contrast?(finding) && below_minimum?(finding, minimum) }
    filtered.each { |finding| tracker.report finding }

    Glue.debug "Have #{tracker.findings.count} items post Contrast severity filter."
  rescue Exception => e
    puts e
    puts e.backtrace.inspect
  end
  end

  private
  def contrast? finding
    finding.task == "Contrast"
  end
  
  def below_minimum? finding, minimum
    if is_number?(finding.severity)
      finding_severity = Float(finding.severity)
    else
      finding_severity = SEVERITIES[finding.severity.upcase]
    end

    finding_severity < minimum
  end

  def is_number? string
    true if Float(string) rescue false
  end
end
