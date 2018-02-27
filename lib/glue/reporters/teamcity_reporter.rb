require 'glue/finding'

class Glue::TeamCityReporter < Glue::BaseReporter

  Glue::Reporters.add self

  def initialize()
    @name = "TeamCityReporter"
    @format = :to_teamcity
  end

  def run_report(tracker)
    min_level = 3 

    if (tracker.options[:teamcity_min_level])
      unless tracker.options[:teamcity_min_level].is_a? Integer
        Glue.fatal "min level should be a number, got: #{tracker.options[:teamcity_min_level]}"
      end
      unless tracker.options[:teamcity_min_level] >= 1 && tracker.options[:teamcity_min_level] <= 3
        Glue.fatal "min level should be between 1 to 3, not #{tracker.options[:teamcity_min_level]}"
      end
      min_level = tracker.options[:teamcity_min_level]
    end
    reports = [ ]

    output = ""

    output << "##teamcity[message text='Report failed tests for each finding with severity equal or above #{printSeverity(min_level)}' status='NORMAL']" << "\n"

    tracker.findings.group_by{|finding| finding.task}.each do |task, task_findings|
      output << "##teamcity[testSuiteStarted name='#{task}']" << "\n"
      task_findings.each do |finding|
        if finding.severity < min_level
          output << "##teamcity[testIgnored name='#{escapeString(finding.fingerprint)}' message='Severity #{printSeverity(finding.severity)}']" << "\n"
          next
        end

        output << "##teamcity[testStarted name='#{escapeString(finding.fingerprint)}' captureStandardOutput='true']" << "\n"
        output << "##teamcity[testFailed name='#{escapeString(finding.fingerprint)}' message='Severity #{printSeverity(finding.severity)}' details='#{escapeString(finding.description)}']" << "\n"
        output << "Source: #{finding.source}" << "\n"
        output << "##teamcity[testFinished name='#{escapeString(finding.fingerprint)}']" << "\n"
      end
      output << "##teamcity[testSuiteFinished name='#{task}']"  << "\n"
      
      return output
    end
  end

  def out(finding)
  end

  def printSeverity(severity)
    case severity
    when 1
      return "Low"
    when 2
      return "Medium"
    when 3
      return "High"
    return "Not supported"
    end
  end

  def escapeString(text)
    return text.gsub('|', '||').gsub('\n', '|n').gsub('\r', '|r').gsub('\'', '|\'').gsub('[', '|[').gsub(']', '|]')
  end

  def combine_reports(reports)
    reports.join
  end
end
