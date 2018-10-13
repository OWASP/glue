require 'glue/tasks/base_task'
require 'json'
require 'glue/util'
require 'pathname'

# This was written live during AppSecUSA 2018.
class Glue::SafetyCheck < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "SafetyCheck"
    @description = "Source analysis for Python"
    @stage = :code
    @labels << "code" << "python"
  end

  def run
    rootpath = @trigger.path
    @result=runsystem(true, "safety", "check", "--json", "-r", "#{rootpath}/requirements.txt")
  end

  def analyze
    puts @result
    results = clean_result(@result)
    begin
      parsed = JSON.parse(results)
      parsed.each do |item|  
        source = { :scanner => @name, :file => "#{item[0]} #{item[2]} from #{@trigger.path}/requirements.txt", :line => nil, :code => nil }
        report "Library #{item[0]} has known vulnerabilities.", item[3], source, severity("medium"), fingerprint(item[3]) 
      end 
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
      Glue.warn "Raw result: #{@result}"
    end
  end

  def supported?
    supported=runsystem(true, "safety", "check", "--help")
    if supported =~ /command not found/
      Glue.notify "Install python and pip."
      Glue.notify "Run: pip install safety"
      Glue.notify "See: https://github.com/pyupio/safety"
      return false
    else
      return true
    end
  end

  def clean_result(result)
    cleaned = ""
    list = result.split(/\n/)
    list.each do |result|
      if result =~ /^Warning:/ 
        Glue.warn "Problem: #{result}"
      else
        cleaned << result
      end
    end
    return cleaned
  end

end
