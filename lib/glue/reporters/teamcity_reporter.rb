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
        Glue.fatal "min level should be a number, got: #{tracker.options[:teamcity-min-level]}"
      end
      unless tracker.options[:teamcity_min_level] < 1 || tracker.options[:teamcity-min-level] > 3
        Glue.fatal "min level should be between 1 to 3, not #{tracker.options[:teamcity-min-level]}"
      end
      min_level = tracker.options[:teamcity_min_level]
    end
    reports = [ ]

    puts "##teamcity[message text='Report failed tests for each finding with severity equal or above #{printSeverity(min_level)}' status='NORMAL']"

    tracker.findings.group_by{|finding| finding.task}.each do |task, task_findings|
      puts "##teamcity[testSuiteStarted name='#{task}']"
      task_findings.each do |finding|
        if finding.severity < min_level
          puts "##teamcity[testIgnored name='#{finding.fingerprint}' message='Severity #{printSeverity(finding.severity)}']"
          return
        end

        puts "##teamcity[testStarted name='#{finding.fingerprint}' captureStandardOutput='true']"
        puts "##teamcity[testFailed name='#{finding.fingerprint}' message='Severity #{printSeverity(finding.severity)}' details='#{finding.description}']"
        puts "Source: #{finding.source}"
        puts "##teamcity[testFinished name='#{finding.fingerprint}']"
      end
      puts "##teamcity[testSuiteFinished name='#{task}']"
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

  def combine_reports(reports)
    reports.join
  end
end
