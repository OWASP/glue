require 'spec_helper'
require 'rspec/collection_matchers'
require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/dynamic'

describe Glue::Dynamic do

  DYNAMIC_TARGETS_PATH = 'spec/tasks/dynamic/targets'

  def get_dynamic_task(report_path, mapping_path)
    trigger = Glue::Event.new(report_path)
    tracker = Glue::Tracker.new({})
    tracker.options[:target] = File.join(DYNAMIC_TARGETS_PATH, report_path)
    tracker.options[:mapping_file_path] = File.join(DYNAMIC_TARGETS_PATH, mapping_path)
    Glue::Dynamic.new(trigger, tracker)
  end

  def get_dynamic_task_buildin_mapping(report_path, mapping_name)
    trigger = Glue::Event.new(report_path)
    tracker = Glue::Tracker.new({})
    tracker.options[:target] = File.join(DYNAMIC_TARGETS_PATH, report_path)
    tracker.options[:mapping_file_path] = "#{mapping_name}"
    Glue::Dynamic.new(trigger, tracker)
  end

  describe "#initialize" do
    let(:task) { @task }
    before(:all) { @task = get_dynamic_task "", "" }

    it "sets the correct 'name'" do
      expect(task.name).to eq('Dynamic Task')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:code)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w(code).to_set)
    end
  end

  describe "#supported?" do
    # TODO --
    # It's not ideal to have to stub 'find_executable0' to test 'supported?',
    # but I'm not sure if there's another way.

    subject(:task) { get_dynamic_task "", "" }

    it { is_expected.to be_supported }
  end

  describe "#run" do 
    subject(:task_findings) { task.findings }
    context "valid file" do
      let(:task) { get_dynamic_task "dummy/report.json", "dummy/mapping.json"}
      before do 
        task.run
      end
      it "should produce one finding" do
        should have(1).items
      end

      it "should fill all the required fields" do
        finding = subject[0]
        expect(finding.severity).to eq(3)
        expect(finding.description).to eq("desc")
        expect(finding.detail).to eq("detail")
        expect(finding.source).to eq("source")
        expect(finding.fingerprint).to eq("fingerprint")
        expect(finding.appname).to eq("test")
        expect(finding.task).to eq("dummy")
      end
    end

    shared_examples 'failure cases' do |report_file, mapping_file|
      let(:task) { get_dynamic_task "dummy/#{report_file}", "dummy/#{mapping_file}"}
      before do 
        allow(Glue).to receive(:fatal).and_raise("boom")
        begin
          task.run
        rescue 
        end
      end
      it "should not produce findings" do
        should have(0).items
      end

      it "should raise fatal error" do
        expect(Glue).to have_received(:fatal)
      end
    end
    

    context "invalid schema" do
      include_examples 'failure cases', "report.json", "invalid_schema.json"
    end
    context "invalid report" do
      include_examples 'failure cases', "invalid_report.json", "mapping.json"
    end
    context "missing report" do
      include_examples 'failure cases', "missing.json", "mapping.json"
    end
    context "missing schema" do
      include_examples 'failure cases', "report.json", "missing.json"
    end
  end


  context "mobsf" do
    let(:task) { get_dynamic_task_buildin_mapping "tools_samples/mobsf.json", "mobsf"}
    subject(:task_findings) { task.findings }
    before do 
      task.run
    end
    it "should produce one finding" do
      should have(7).items
    end

    it "should fill all the required fields" do
      finding = subject[0]
      expect(finding.severity).to eq(2)
      expect(finding.description).to eq("This flag allows anyone to backup your application data via adb. It allows users who have enabled USB debugging to copy application data off of the device.")
      expect(finding.detail).to eq("Application Data can be Backed up<br>[android:allowBackup=true]")
      expect(finding.source).to eq("Application Data can be Backed up<br>[android:allowBackup=true]")
      expect(finding.fingerprint).to eq("Application Data can be Backed up<br>[android:allowBackup=true]")
      expect(finding.appname).to eq("InsecureBankv2.apk")
      expect(finding.task).to eq("MobSF")
    end
  end
 end
