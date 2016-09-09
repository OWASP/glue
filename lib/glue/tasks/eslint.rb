require 'glue/tasks/base_task'
require 'json'
require 'glue/util'

class Glue::ESLint < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger,tracker)
    @name = "ESLint/ScanJS"
    @description = "Source analysis for JavaScript"
    @stage = :code
    @labels << "code" << "javascript"
  end

  def run
    rootpath = @trigger.path
    currentpath = File.expand_path File.dirname(__FILE__)
    Glue.debug "ESLint Config Path: #{currentpath}"
    @result = `eslint -c #{currentpath}/scanjs-eslintrc --no-color --quiet --format json #{rootpath}`
  end

  def analyze
    # puts @result
    begin
      parsed = JSON.parse(@result)
      parsed.each do |result|
        findings = {}
        prints = []
        messages = []
        result['messages'].each do |msg|
          message = msg['message']
          findings[message] = {} if findings[message].nil?
          findings[message][:detail] = msg['ruleId']
          if messages.include?(message)
            findings[message][:source] = "#{findings[message][:source]},#{msg['line']}" unless findings[message][:source].include?(",#{msg['line']}")
          else
            findings[message][:source] = "#{result['filePath']} Line: #{msg['line']}"
            messages << message
          end
          findings[message][:severity] = severity(msg['severity'].to_s)
        end
        findings.each do |key, value|
          print = fingerprint("#{key}#{value[:detail]}#{value[:source]}#{value[:sev]}")
          unless prints.include?(print)
            prints << print
            report key, value[:detail], value[:source], value[:severity], print
          end
        end
      end
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, "eslint", "-c", "~/.scanjs-eslintrc")
    if supported =~ /command not found/
      Glue.notify "Install eslint and the scanjs .eslintrc"
      return false
    else
      return true
    end
  end

end
