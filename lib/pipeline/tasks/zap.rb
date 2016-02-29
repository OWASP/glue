require 'pipeline/tasks/base_task'
require 'pipeline/util'
require 'json'
require 'curb'
require 'securerandom'

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
    apikey = "#{@tracker.options[:zap_api_token]}"
    context = SecureRandom.uuid

    Pipeline.debug "Running ZAP on: #{rootpath} from #{base} with #{context}"
    
    # Set up Context
    Curl.get("#{base}/JSON/context/action/newContext/?&apikey=#{apikey}&contextName=#{context}")
    Curl.get("#{base}/JSON/context/action/includeInContext/?apikey=#{apikey}&contextName=#{context}&regex=#{rootpath}.*")

    # Spider
    spider = get_scan_id( Curl.get("#{base}/JSON/spider/action/scan/?apikey=#{apikey}&url=#{rootpath}&context=#{context}") )
    poll_until_100("#{base}/JSON/spider/view/status/?scanId=#{spider}")

    # Active Scan
    scan = get_scan_id ( Curl.get("#{base}/JSON/ascan/action/scan/?apikey=#{apikey}&recurse=true&inScopeOnly=true&url=#{rootpath}") )
    poll_until_100("#{base}/JSON/ascan/view/status/?scanId=#{scan}")
      
    # Result
    @result = Curl.get("#{base}/JSON/core/view/alerts/?baseurl=#{rootpath}").body_str

    # Remove Context
    Curl.get("#{base}/JSON/context/action/removeContext/?&apikey=#{apikey}&contextName=#{context}")
  end

  def get_scan_id(response)
    json = JSON.parse response.body_str
    return json["scan"]
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

