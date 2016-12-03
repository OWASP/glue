require 'glue/filters/base_filter'
require 'jira-ruby'

class Glue::JiraOneTimeFilter < Glue::BaseFilter

  Glue::Filters.add self

  def initialize
    @name = "Jira One Time Filter"
    @description = "Checks that each issue that will be reported doesn't already exist in JIRA."
    @format = :to_jira
  end

  def filter tracker

    if !tracker.options[:output_format].include?(@format)
      return  # Bail in the case where JIRA isn't being used.
    end
    Glue.debug "Have #{tracker.findings.count} items pre JIRA One Time filter."
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

    potential_findings = Array.new(tracker.findings)
    tracker.findings.clear
    potential_findings.each do |finding|
    	if confirm_new finding
    		tracker.report finding
    	end
    end
    Glue.debug "Have #{tracker.findings.count} items post JIRA One Time filter."
  end

  private
  def confirm_new finding
    count = 0
    
    @jira.Issue.jql("project=#{@project} AND description ~ '#{finding.fingerprint}' AND resolution is EMPTY").each do |issue|
      count = count + 1  # Must have at least 1 issue with fingerprint.
    end
    Glue.debug "Found #{count} items for #{finding.description}"
    if count > 0 then
      return false
    else
      return true # New!
    end
  end

end
