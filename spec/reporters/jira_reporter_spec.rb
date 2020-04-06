require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/finding'
require 'glue/reporters'
require 'glue/reporters/jira_reporter'

describe Glue::JiraReporter do

    describe "JIRA Reporter" do
        subject {Glue::JiraReporter.new()}

        it "should set jira issue type to Bug when no type given" do
            expected_output = "Bug"
            actual_output_example_1 = subject.send("jira_issue_type", nil)
            actual_output_example_2 = subject.send("jira_issue_type", "")

            expect(expected_output).to eq(actual_output_example_1)
            expect(expected_output).to eq(actual_output_example_2)
        end

        it "should set jira issue to type passed by the user" do
            expected_output = "Story"
            actual_output = subject.send("jira_issue_type", "Story")

            expect(expected_output).to eq(actual_output)
        end

    end
end