require 'pipeline/finding'
require 'pipeline/reporters/base_reporter'
require 'json'
require 'curb'

class Pipeline::JiraReporter < Pipeline::BaseReporter

  Pipeline::Reporters.add self

  attr_accessor :name, :format
 
  def initialize()
    @name = "JiraReporter"  
    @format = :to_jira
  end
  
  def run_report(tracker)
    @project = tracker.options[:jira_project.to_s]
    @api = tracker.options[:jira_api_url.to_s]
    @cookie = tracker.options[:jira_cookie.to_s]
    @component = tracker.options[:jira_component.to_s]

    tracker.findings.each do |finding|
    	report finding
    end
    "Results are in JIRA"
  end

  def report(finding)
  	json = get_jira_json(finding)
  	http = Curl.post("#{@api}/issue/", json.to_s) do |http|
  		http.headers['Content-Type'] = "application/json"
  		http.headers['Cookie'] = @cookie
  	end
  	if http.response_code != 201 # Created ...
  		Pipeline.error "Problem with HTTP #{http.response_code} - #{http.body_str}"
  	end
  end

  private 
  def get_jira_json(finding)
	json = {
    	"fields": {
       		"project":
       		{
          		"key": "#{@project}"
       		},
       		"summary": "#{finding.appname} - #{finding.description}",
       		"description": "#{finding.to_string}\n\nFINGERPRINT: #{finding.fingerprint}",
       		"issuetype": {
          		"name": "Task"
       		},
       		"labels":["Pipeline","#{finding.appname}"],
       		"components": [ { "name": "#{@component}" } ]
       	}
	}.to_json
	json
  end
end


# curl -X DELETE -H "Cookie: cookie" https://jira.groupondev.com/rest/api/2/issue/APPS-133