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

    @jira_epic_field_id = tracker.options[:jira_epic_field_id]
    @jira_epic = tracker.options[:jira_epic]

    Glue.debug "Set JIRA epic fields: #{@jira_epic_field_id} / #{@jira_epic}"

    tracker.findings.each do |finding|
      begin
        issue = @jira.Issue.build
        json = get_jira_json(finding, tracker.options[:jira_skip_fields] || '', tracker.options[:jira_default_priority], tracker.options[:jira_issue_type])
        issue.save(json)
      rescue Exception => e
        puts "Issue #{e.message}"
      end
    end
    "Results are in JIRA"
  end

  private
  def get_jira_json(finding, skip_fields, default_priority=nil, issue_type=nil)
	  json = {
    	"fields": {
       		"project":
       		{
          		"key": "#{@project}"
       		},
       		"summary": "#{finding.description}",
       		"description": "#{finding.to_string}",
          "priority": {
            'name': jira_priority(finding.severity, default_priority)
          },
       		"issuetype": {
          		"name": jira_issue_type(issue_type)
       		},       		
       		#{}"components": [ { "name": "#{@component}" } ]
       	}
	    }

    if @jira_epic_field_id.present? && @jira_epic.present?
      json[:fields][@jira_epic_field_id] = @jira_epic
    end    

    json['labels'] = [ "Glue", "#{finding.appname}" ] unless skip_fields.split(',').include?('labels')
    json
  end

  def jira_issue_type(issue_type)
    if issue_type.to_s.empty?
      return "Bug"
    end

    issue_type
  end

  def jira_priority(severity, default_priority=nil)
    return default_priority if default_priority
    if is_number?(severity)
      f = Float(severity)

      if f < 5
        'Low'
      elsif f < 7
        'Medium'
      else
        'High'
      end
    else
      case severity
      when 'Critical' then 'High'
      when 'CRITICAL' then 'High'
      when 'HIGH' then 'High'
      when 'High' then 'High'
      when 'MEDIUM' then 'Medium'
      when 'Medium' then 'Medium'
      when 'NOTE' then 'Low'
      when 'Note' then 'Low'
      when 'Low' then 'Low'
      when 'Information' then 'Low'
      else
        Glue.notify "**** Unknown severity type #{severity}"
        
        severity
      end
    end
  end

  def is_number?(str)
    true if Float(str) rescue false
  end
end
