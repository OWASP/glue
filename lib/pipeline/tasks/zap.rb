require 'pipeline/tasks/base_task'
require 'pipeline/util'
require 'json'
require 'curb'

class Pipeline::Zap < Pipeline::BaseTask

  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger,tracker)
    super(trigger,tracker)
    @name = "ZAP"
    @description = "App Scanning"
    @stage = :live
    @labels << "live"
  end

  def run
    rootpath = @trigger.path
    base = "#{@tracker.options[:zap_host]}:#{@tracker.options[:zap_port]}"
    Pipeline.debug "Running ZAP on: #{rootpath} from #{base}"

    # TODO:  Add API Key
    # TODO:  Find out if we need to worry about "contexts" stepping on each other.

    # Spider
    Curl.get("#{base}/JSON/spider/action/scan/?#{rootpath}")
    poll_until_100("#{base}/JSON/spider/view/status")

    # Active Scan
    Curl.get("#{base}/JSON/ascan/action/scan/?recurse=true&inScopeOnly=true&url=#{rootpath}")
    poll_until_100("#{base}/JSON/ascan/view/status/")
      
    # Result
    @result = Curl.get("#{base}/JSON/core/view/alerts/").body_str
  end

  def poll_until_100(url)
    count = 0
    loop do
      sleep 5
      status = JSON.parse(Curl.get(url).body_str)
      count = count + 1      
      Pipeline.notify "Count ... #{count}"
      break if status["status"] == "100" or count > 100
    end
  end

  def analyze
    begin   
      json = JSON.parse @result
      alerts = json["alerts"]
      count = 0
      alerts.each do |alert|
        count = count + 1
        description = alert["description"]
        detail = "Url: #{alert["url"]} Param: #{alert["param"]} \nReference: #{alert["reference"]}\n"+
                 "Solution: #{alert["solution"]}\nCWE: #{alert["cweid"]}\tWASCID: #{alert["wascid"]}"
        source = @name + alert["url"]
        sev = severity alert["risk"]
        fingerprint = @name + alert["url"] + alert["alert"] + alert["param"]
        report description, detail, source, sev, fingerprint
      end
      Pipeline.debug "ZAP Identified #{count} issues."
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.notify "Problem running ZAP."
    end
  end

  def supported?
    base = "#{@tracker.options[:zap_host]}:#{@tracker.options[:zap_port]}"
    supported=JSON.parse(Curl.get("#{base}/JSON/core/view/version/").body_str)
    if supported["version"] == "2.4.3"
      return true
    else
      Pipeline.notify "Install ZAP from owasp.org and ensure that the configuration to connect is correct."
      return false
    end
  end

end

