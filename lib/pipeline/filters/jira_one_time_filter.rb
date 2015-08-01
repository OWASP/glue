require 'pipeline/filters/base_filter'
require 'json'
require 'curb'

class Pipeline::JiraOneTimeFilter < Pipeline::BaseFilter
  
  # Pipeline::Filters.add self
  
  def initialize
    @name = "Jira One Time Filter"
    @description = "Checks that each issue that will be reported doesn't already exist in JIRA."
  end

  def filter tracker
  	@project = tracker.options[:jira_project.to_s]
    @api = tracker.options[:jira_api_url.to_s]
    @cookie = tracker.options[:jira_cookie.to_s]
    @component = tracker.options[:jira_component.to_s]
    @appname = tracker.options[:appname]

    potential_findings = Array.new(tracker.findings)
    tracker.findings.clear
    potential_findings.each do |finding|
    	if confirm_new finding
    		tracker.report finding
    	end
    end
  end

  private
  def confirm_new finding
  	json = get_jira_query_json finding
  	http = Curl.post("#{@api}/search", json.to_s) do |http|
  		http.headers['Content-Type'] = "application/json"
  		http.headers['Cookie'] = @cookie
  	end
  	if http.response_code != 200 # OK ...
  		Pipeline.error "Problem with HTTP #{http.response_code} - #{http.body_str}"
  	end

  	result = JSON.parse(http.body_str)
  	# Pipeline.error "Got back #{result} with #{result['total']}"

  	if result['total'] < 1
  		return true
  	end
  	return false
  end

  def get_jira_query_json finding
	json = 
{"jql": "project=#{@project} AND component='#{@component}' AND labels='#{@appname}' AND description ~ 'FINGERPRINT: #{finding.fingerprint}'"}.to_json
	json
  end
end

# project = APPS and component = "Automated Findings" and Labels = "service-portal" and description ~ "FINGERPRINT: bundlerauditgemsource"
