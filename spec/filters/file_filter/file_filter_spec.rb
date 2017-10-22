require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/finding'
require 'glue/filters'
require 'glue/filters/file_filter'

describe Glue::FileFilter do
  LOCAL_TEST_DIR = 'spec/filters/file_filter/targets'

  before do
    @tracker = Glue::Tracker.new({})
    @tracker.report Glue::Finding.new( "test", "test", "test", "test", 1, "fingerprint1", self.class.name )
    @tracker.report Glue::Finding.new( "test", "test", "test", "test", 1, "fingerprint2", self.class.name )
    @empty_file_name = File.join(Dir.pwd, LOCAL_TEST_DIR, "empty.json")
    @ignore_file_name = File.join(Dir.pwd, LOCAL_TEST_DIR, "finding_ignore.json")
    @partial_file_name = File.join(Dir.pwd, LOCAL_TEST_DIR, "finding_partial.json")
    @postpone_file_name = File.join(Dir.pwd, LOCAL_TEST_DIR, "finding_postpone.json")
    @postpone_passed_file_name = File.join(Dir.pwd, LOCAL_TEST_DIR, "finding_postpone_passed.json")
  end

  describe "filter" do
    subject {Glue::FileFilter.new()}
    describe "finding file does not exist" do
        before do 
            @tracker.options[:finding_file_path] = @empty_file_name
        end

        after do 
            if File.exist? @empty_file_name
                File.delete @empty_file_name
            end
        end

        it "should write all finding to file with state 'new'" do
            subject.filter(@tracker)
            results = JSON.parse!(File.read @empty_file_name)
            expect(results.length).to eq(2)
            expect(results["fingerprint1"]).to eq("new")
            expect(results["fingerprint2"]).to eq("new")
        end

        it "should not filter the results" do
            current_findings = Array.new(@tracker.findings)
            subject.filter(@tracker)
            expect(@tracker.findings).to eq(current_findings)
        end
    end

    describe "finding file contains ignored findings" do
        before do 
            @tracker.options[:finding_file_path] = @ignore_file_name
        end

        it "should not change the file" do
            subject.filter(@tracker)
            puts @ignore_file_name
            results = JSON.parse!(File.read @ignore_file_name)
            expect(results.length).to eq(2)
            expect(results["fingerprint1"]).to eq("ignore")
            expect(results["fingerprint2"]).to eq("new")
        end

        it "should filter the results" do
            subject.filter(@tracker)
            expect(@tracker.findings.length).to eq(1)
        end
    end

    describe "finding file contains partial results" do
        before do 
            @tracker.options[:finding_file_path] = @partial_file_name
        end

        it "should not change the file" do
            subject.filter(@tracker)
            puts @ignore_file_name
            results = JSON.parse!(File.read @partial_file_name)
            expect(results.length).to eq(2)
            expect(results["fingerprint1"]).to eq("ignore")
            expect(results["fingerprint2"]).to eq("new")
        end

        it "should filter the results" do
            subject.filter(@tracker)
            expect(@tracker.findings.length).to eq(1)
        end
    end

    describe "finding file contains postponed results" do
        before do 
            @tracker.options[:finding_file_path] = @postpone_file_name
        end

        it "should not change the file" do
            subject.filter(@tracker)
            puts @ignore_file_name
            results = JSON.parse!(File.read @postpone_file_name)
            expect(results.length).to eq(2)
            expect(results["fingerprint1"]).to eq("postpone:1-1-2999")
            expect(results["fingerprint2"]).to eq("new")
        end

        it "should filter the results" do
            subject.filter(@tracker)
            expect(@tracker.findings.length).to eq(1)
        end
    end

    describe "finding file contains postponed results" do
        before do 
            @tracker.options[:finding_file_path] = @postpone_passed_file_name
        end

        it "should not change the file" do
            subject.filter(@tracker)
            puts @ignore_file_name
            results = JSON.parse!(File.read @postpone_passed_file_name)
            expect(results.length).to eq(2)
            expect(results["fingerprint1"]).to eq("postpone:1-1-1")
            expect(results["fingerprint2"]).to eq("new")
        end

        it "should filter the results" do
            subject.filter(@tracker)
            expect(@tracker.findings.length).to eq(2)
        end
    end
  end

  # The "::matches?" method was tested implicitly in the tests for "#analyze"
  # (all of the allowed combinations were included there)
  # so no explicit tests for it are done here.
end
