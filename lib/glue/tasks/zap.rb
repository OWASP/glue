require 'glue/tasks/base_task'
require 'glue/util'
require 'json'
require 'curb'
require 'securerandom'

class Glue::Zap < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

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

    Glue.debug "Running ZAP on: #{rootpath} from #{base} with #{context}"

    # Create a new session so that the findings will be new.
    Curl.get("#{base}/JSON/core/action/newSession/?zapapiformat=JSON&apikey=#{apikey}&name=&overwrite=")

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
      Glue.notify "Count ... #{count}"
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
      Glue.debug "ZAP Identified #{count} issues."
    rescue Exception => e
      Glue.warn e.message
      Glue.notify "Problem running ZAP."
    end
  end

  def supported?
    apikey = "#{@tracker.options[:zap_api_token]}"
    base = "#{@tracker.options[:zap_host]}:#{@tracker.options[:zap_port]}"
    begin
      supported=JSON.parse(Curl.get("#{base}/JSON/core/view/version/?apikey=#{apikey}").body_str)
    rescue Exception => e
      Glue.error "#{e.message}. Tried to connect to #{base}/JSON/core/view/version/. Check that ZAP is running on the right host and port and that you have the appropriate API key, if required."
      return false
    end
    if supported["version"] =~ /2.(4|5|6).\d+/
      return true
    else
      Glue.notify "Install ZAP from owasp.org and ensure that the configuration to connect is correct.  Supported versions = 2.4.0 and up - got #{supported['version']}"
      return false
    end
  end

end
