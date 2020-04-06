require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/finding'
require 'glue/reporters'
require 'glue/reporters/slack_reporter'

describe Glue::SlackReporter do

    before do
        @tracker = Glue::Tracker.new({
            slack_token: "",
            slack_channel: ""
        })

        @tracker.report Glue::Finding.new( "finding_appname",
            "finding_description",
            "finding_detail",
            "finding_test",
            1,
            "fingerprint_1",
            "finding_task" )
      end

    describe "Slack Reporter" do
        subject {Glue::SlackReporter.new()}

        it "should report findings as a slack message with an attachment" do
            # Stub out requests to Slack API
            stub_request(:post, "https://slack.com/api/auth.test")
                .to_return(status: 200, body: "", headers: {})

            stub_request(:post, "https://slack.com/api/chat.postMessage")
                .to_return(status: 200, body: "", headers: {})

            
            # Build slack report
            subject.run_report(@tracker)

            # Check slack client made request to send message with attachment for findings
            WebMock.should have_requested(:post, "https://slack.com/api/chat.postMessage")
                .with{|req|
                    req.body.include?("attachments=%0A%09Description%3A+finding_description")
                    req.body.include?("text=OWASP+Glue+test+run+completed+-+See+attachment.")
                }
        end
    end
end