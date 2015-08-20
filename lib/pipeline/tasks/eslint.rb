require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'

class Pipeline::ESLint < Pipeline::BaseTask

  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger)
    super(trigger)
    @name = "ESLint/ScanJS"
    @description = "Source analysis for JavaScript"
    @stage = :code
    @labels << "code" << "javascript"
    @severity_filter = {
      :low => [ '1' ],
      :medium => [ '2' ],
      :high => [ '3' ]
    }
  end

  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    #@result=runsystem(true, "eslint", "-c", "/Users/alock/.scanjs-eslintrc", "--format", "json", "#{rootpath}")
    @result = `cd #{rootpath} && eslint -c /Users/alock/.scanjs-eslintrc --no-color --quiet --format json .`
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
      Pipeline.warn e.message
      Pipeline.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, "eslint", "-c", "~/.scanjs-eslintrc")
    if supported =~ /command not found/
      Pipeline.notify "Install eslint and the scanjs .eslintrc"
      return false
    else
      return true
    end
  end

end

