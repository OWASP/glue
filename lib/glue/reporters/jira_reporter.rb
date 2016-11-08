require 'glue/finding'
require 'glue/reporters/base_reporter'
require 'jira-ruby'

# In IRB
# require 'jira-ruby'
# options = { :username => 'jira@site.com', :password => 'whatever', :site => 'https://site.atlassian.net', :context_path => '', :auth_type => :basic }
# jira = JIRA::Client.new(options)
# issue = jira.Issue.build
# issue.save json_for_issue

class Glue::JiraReporter < Glue::BaseReporter

  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "JiraReporter2"
    @format = :to_jira
  end

  def run_report(tracker)
    options = {
      :username     => tracker.options[:jira_username],
      :password     => tracker.options[:jira_password],
      :site         => tracker.options[:jira_api_url],
      :context_path => tracker.options[:jira_api_context],
      :auth_type    => :basic,
      :http_debug   => :true
    }
    @project = tracker.options[:jira_project]
    @component = tracker.options[:jira_component]
    @jira = JIRA::Client.new(options)

    tracker.findings.each do |finding|
      begin
        issue = @jira.Issue.build
        json = get_jira_json finding
        issue.save(json)
      rescue Exception => e
        puts "Issue #{e.message}"
      end
    end
    "Results are in JIRA"
  end

  private
  def get_jira_json(finding)
	  json = {
    	"fields": {
       		"project":
       		{
          		"key": "#{@project}"
       		},
       		"summary": "#{finding.description}",
       		"description": "#{finding.to_string}",
       		"issuetype": {
          		"name": "Bug"
       		},
       		"labels":["Glue","#{finding.appname}"]
       		#{}"components": [ { "name": "#{@component}" } ]
       	}
	    }
    json
  end
end
