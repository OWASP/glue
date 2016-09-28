require 'glue/finding'
require 'glue/reporters/base_reporter'
require 'curb'
require 'json'

class Glue::PivotalReporter < Glue::BaseReporter

  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "PivotalReporter"
    @format = :to_pivotal
  end

#  export TOKEN='your Pivotal Tracker API token'
#  export PROJECT_ID=99
#  curl -X POST -H "X-TrackerToken: $TOKEN" -H "Content-Type: application/json" -d '{"current_state":"started","estimate":1,"name":"Exhaust ports are ray shielded"}' "https://www.pivotaltracker.com/services/v5/projects/$PROJECT_ID/stories"

  def run_report(tracker)
    @project = tracker.options[:pivotal_project]
    @token = tracker.options[:pivotal_token]
    @api = tracker.options[:pivotal_api_url]
    @url = "#{@api}/#{@project}/stories"

    tracker.findings.each do |finding|
      begin
        Glue.debug "Posting to #{@url}"
        Glue.debug get_pivotal_json(finding)
        c = Curl.post(@url, get_pivotal_json(finding)) do |curl|
          curl.headers['Content-Type'] = 'application/json'
          curl.headers['X-TrackerToken'] = "#{@token}"
          #curl.verbose=true
        end
        Glue.debug c.body_str
      rescue Exception => e
        puts "Issue #{e.message}"
      end
    end
    "Results are in Pivotal"
  end

  private
  def get_pivotal_json(finding)
	  json = {"current_state": "unscheduled",
            "estimate": 1,
            "name": "#{finding.appname} - #{finding.description}",
            "description": "#{finding.to_string}\n\nFINGERPRINT: #{finding.fingerprint}",
            "labels": ["Glue", "#{finding.appname}","#{finding.fingerprint}"]
          }
    json.to_json
  end

  #

end
