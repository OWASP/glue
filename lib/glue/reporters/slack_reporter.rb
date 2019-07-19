require 'glue/finding'
require 'glue/reporters/base_reporter'
require 'jira-ruby'
require 'slack-ruby-client'


# In IRB
# require 'slack-ruby-client'
# Slack.configure do |config|
#   config.token = "token"
# end
# client = Slack::Web::Client.new
# client.chat_postMessage(channel: 'channel_name', text: "message_text", attachments: json_attachment, as_user: post_as_user)


class Glue::SlackReporter < Glue::BaseReporter
  Glue::Reporters.add self

  attr_accessor :name, :format

  def initialize()
    @name = "SlackReporter"
    @format = :to_slack
  end

  def is_number?(str)
    true if Float(str) rescue false
  end

  def get_slack_attachment(finding)
    json = {
      "fallback": "Results of OWASP Glue test for repository #{tracker.options[:appname]}:",
      "color": slack_priority(finding.severity),
      "title": "#{finding.description}",
      "title_link":"#{finding.detail}",
      "text":"#{finding.source}"
    }
  end

  def slack_priority(severity)
    if is_number?(severity)
      f = Float(severity)
      if f == 3
        'warning'
      elsif f == 2
        'danger'
      elsif f == 1
        '#192022'
      else
        Glue.notify "**** Unknown severity type #{severity}"
        severity
    end
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
        begin
          reports << get_slack_attachment(finding)
          binding.pry
        end
      reports.join
      end

      puts tracker.options[:slack_channel]

      begin
        client.chat_postMessage(channel: tracker.options[:slack_channel], text: "OWASP Glue test run completed - See attachment.", attachments: reports.to_json << "\n", as_user: post_as_user)
      rescue Slack::Web::Api::Error => error
        Glue.fatal "Post to slack failed: " << error.to_s
      end
    end
  end
end
