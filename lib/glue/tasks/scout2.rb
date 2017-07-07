require 'glue/tasks/base_task'
require 'json'
require 'glue/util'
require 'securerandom'

class Glue::Scout < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Scout"
    @description = "Security review for your AWS environment"
    @stage = :live
    @labels << "cloud" << "aws"
  end

  # TODO AWS Credentials
  # TODO Docker image
  # TODO Cleanup issues - release 1.0
  
  def run
    rootpath = @trigger.path
    context = SecureRandom.uuid
    @tmppath = "/tmp/#{context}/"    
    runsystem(true, "Scout2", "--no-browser", "--report-dir", "#{@tmppath}")
    file = File.open("#{@tmppath}/inc-awsconfig/aws_config.js", "rb")
    @result= file.read
  end

  def analyze
    begin
      # Glue.warn @result
      start = @result.index('{')  #  First we need to take out the variable = part which is not proper JSON 
      json = @result.slice(start, @result.size)
      parsed = JSON.parse(json)
      count = 0
      parsed["services"].each do |servicename, servicesjson|
        #  This would be a chance to skip a named service...
        if servicesjson["findings"] then  #  Have seen this as empty / nil in practice
          servicesjson["findings"].each do |findingname, detail|
            count = count + 1
            severity = "low"
            if detail["level"] === "danger" then severity = "high" end

            source = { :scanner => @name,
                       :service => servicename,
                       :findingname => findingname
                       # TODO Add region?
                     }

            # This would be a place to only report danger.  (If Sev low)
            report findingname,
                   detail["description"],
                   source,
                   severity,
                   fingerprint(source.to_s)
                   
          end
        end
      end
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
      Glue.warn "Raw result: #{@result}"
    end
  end

  def supported?
    supported=runsystem(true, "Scout2", "-h")
    if supported =~ /usage: Scout2/
      return true
    else
      Glue.notify "Install python and pip."
      Glue.notify "Run: pip install awsscout"
      Glue.notify "See: https://github.com/nccgroup/Scout2"
      return false
    end
  end

end
