require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/finding'
require 'glue/reporters'
require 'glue/reporters/teamcity_reporter'

describe Glue::TeamCityReporter do

  before do
    @tracker = Glue::Tracker.new({})
    @tracker.report Glue::Finding.new( "test", "test", "test", "test", 1, "fingerprint1", "some test" )    
  end

  describe "TeamCity Reporter" do
    subject {Glue::TeamCityReporter.new()}
    describe "Report non-high finding as ignored tests" do

        it "should write all finding to file with state 'new'" do
            output = subject.run_report(@tracker)
            expected = %q(##teamcity[message text='Report failed tests for each finding with severity equal or above High' status='NORMAL']
##teamcity[testSuiteStarted name='some test']
##teamcity[testIgnored name='fingerprint1' message='Severity Low']
##teamcity[testSuiteFinished name='some test']
)
            expect(output).to eq(expected)
        end
    end

    describe "Report all finding as failing tests when setting the appropriate level" do
        before do 
            @tracker.options[:teamcity_min_level] = 1
        end

        it "should write all finding to file with state 'new'" do
            output = subject.run_report(@tracker)
            expected = %q(##teamcity[message text='Report failed tests for each finding with severity equal or above Low' status='NORMAL']
##teamcity[testSuiteStarted name='some test']
##teamcity[testStarted name='fingerprint1' captureStandardOutput='true']
Source: test
Details: test
##teamcity[testFailed name='fingerprint1' message='Severity Low' details='test']
##teamcity[testFinished name='fingerprint1']
##teamcity[testSuiteFinished name='some test']
)
            expect(output).to eq(expected)
        end
    end
  end
end