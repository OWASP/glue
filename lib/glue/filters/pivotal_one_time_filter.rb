require 'glue/filters/base_filter'
require 'curb'
require 'json'

class Glue::PivotalOneTimeFilter < Glue::BaseFilter

  Glue::Filters.add self

  def initialize
    @name = "Pivotal One Time Filter"
    @description = "Checks that each issue that will be reported doesn't already exist in Pivotal."
    @format = :to_pivotal
  end

#  export TOKEN='your Pivotal Tracker API token'
#  export PROJECT_ID=99
#  curl -X GET -H "X-TrackerToken: $TOKEN" "https://www.pivotaltracker.com/services/v5/projects/$PROJECT_ID/stories?date_format=millis&filter=label%3Aplans"

  def filter tracker
    if !tracker.options[:output_format].include?(@format)
      return  # Bail in the case where JIRA isn't being used.
    end
    @project = tracker.options[:pivotal_project]
    @token = tracker.options[:pivotal_token]
    @api = tracker.options[:pivotal_api_url]
    @url = "#{@api}/#{@project}/stories"

    Glue.debug "Have #{tracker.findings.count} items pre Pivotal One Time filter."

    potential_findings = Array.new(tracker.findings)
    tracker.findings.clear
    potential_findings.each do |finding|
    	if confirm_new finding
    		tracker.report finding
    	end
    end
    Glue.debug "Have #{tracker.findings.count} items post Pivotal One Time filter."
  end

  private
  def confirm_new finding
    count = 0
    filter_url = "#{@url}?filter=label:#{finding.fingerprint}"
    c = Curl.get(filter_url) do |curl|
      curl.headers['Content-Type'] = 'application/json'
      curl.headers['X-TrackerToken'] = "#{@token}"
      #curl.verbose=true
    end
    json = c.body_str
    Glue.debug "JSON response: #{json}"
    items = JSON.parse(json)
    count = items.count
    Glue.debug "Found #{count} items for #{finding.description}"
    if count > 0 then
      return false
    else
      return true # New!
    end
  end

end
