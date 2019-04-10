require 'glue/finding'
require 'glue/reporters/base_reporter'
require 'jira-ruby'
require 'slack-ruby-client'

class Glue::SlackReporter < Glue::BaseReporter
  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "SlackReporter"
    @format = :to_slack
  end

  def run_report(tracker)
    post_as_user = false
    if (tracker.options[:slack_post_as_user])
      post_as_user = true
    end

    mandatory = [:slack_token, :slack_channel]   
    missing = mandatory.select{ |param| tracker.options[param].nil? }     
    unless missing.empty?                                           
      Glue.fatal "missing one or more required params: #{missing}"
      return
    end  

    Slack.configure do |config|
        config.token = tracker.options[:slack_token]
    end

    client = Slack::Web::Client.new
    
    begin
      client.auth_test
    rescue Slack::Web::Api::Error => error
      Glue.fatal "Slack authentication failed: " << error.to_s
    end

    reports = []
    tracker.findings.each do |finding|
      reports << finding.to_string
    end

    puts tracker.options[:slack_channel]

    begin
      client.chat_postMessage(channel: tracker.options[:slack_channel], text: "OWASP Glue found some issues. Raised as a message attachment.", attachments: reports.join << "\n", as_user: post_as_user)
    rescue Slack::Web::Api::Error => error
      Glue.fatal "Post to slack failed: " << error.to_s
    end
  end
end
