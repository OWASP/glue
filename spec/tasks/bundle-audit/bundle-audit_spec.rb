require 'spec_helper'
require 'rspec/collection_matchers'
require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/bundle-audit'

describe Glue::BundleAudit do

  BUNDLEAUDIT_TARGETS_PATH = 'spec/tasks/bundle-audit/targets'

  def get_bundleaudit(target = 'nil_target')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(BUNDLEAUDIT_TARGETS_PATH, target)
    tracker = Glue::Tracker.new({})
    Glue::BundleAudit.new(trigger, tracker)
  end

  def get_raw_report(target, subtarget = nil)
    path = File.join(get_target_path(target, subtarget), "report.txt")
    File.read(path).chomp
  end

  def get_target_path(target, subtarget = nil)
    if subtarget.nil?
      File.join(BUNDLEAUDIT_TARGETS_PATH, target)
    else
      File.join(BUNDLEAUDIT_TARGETS_PATH, target, subtarget)
    end
  end

  def cli_args(target, subtarget = nil)
    [true, "bundle-audit", "check", { chdir: get_target_path(target, subtarget) }]
  end

  describe "#initialize" do
    let(:task) { @task }
    before(:all) { @task = get_bundleaudit }

    it "sets the correct 'name'" do
      expect(task.name).to eq('BundleAudit')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:code)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w[code ruby].to_set)
    end
  end

  describe '#supported?' do
    subject(:task) { get_bundleaudit }

    context "when 'runsystem' cannot run the task" do
      before do
        allow(Glue).to receive(:notify) # suppress the output
        cmd_args = [false, "bundle-audit", "update"]
        cmd_str = 'command not found'
        allow(task).to receive(:runsystem).with(*cmd_args).and_return(cmd_str)
      end

      it { is_expected.not_to be_supported }

      it 'issues a notification' do
        expect(Glue).to receive(:notify)
        task.supported?
      end
    end

    context "when 'runsystem' returns an updating message" do
      before do
        cmd_args = [false, "bundle-audit", "update"]
        cmd_str = 'Updating ruby-advisory-db ...'
        allow(task).to receive(:runsystem).with(*cmd_args).and_return(cmd_str)
      end

      it { is_expected.to be_supported }
    end
  end

  describe "#run" do
    let(:task) { get_bundleaudit target }
    let(:minimal_response) { "No vulnerabilities found" }

    before do
      allow(Glue).to receive(:notify) # suppress the output
      allow(Glue).to receive(:warn) # suppress the output

      # This acts as a guard against actually calling bundle-audit from the CLI.
      # (All specs should use canned responses instead.)
      allow(task).to receive(:runsystem) do
        puts "Warning from rspec -- make sure you're not attempting to call the actual bundle-audit CLI"
        puts "within an 'it' block with description '#{self.class.description}'"
        minimal_response
      end
    end

    context "with no Gemfile.lock file in root, and no sub-dirs" do
      let(:target) { 'no_findings_no_gemfile_lock' }

      it "does not call bundle-audit on the target" do
        expect(task).not_to receive(:runsystem).with(*cli_args(target))
        task.run
      end
    end

    context 'assuming valid (but minimal) reports' do
      context 'with one Gemfile.lock in the root dir' do
        let(:target) { 'finding_1' }

        before do
          allow(task).to receive(:runsystem).with(*cli_args(target))
        end

        it 'passes the task name to Glue.notify' do
          expect(Glue).to receive(:notify).with(/^BundleAudit/)
          task.run
        end

        it "calls the 'bundle-audit' cli once, from the root dir" do
          expect(task).to receive(:runsystem).with(*cli_args(target))
          task.run
        end

      end

    end
  end

  describe "#analyze" do
    let(:task) { get_bundleaudit target }
    let(:minimal_response) { "No vulnerabilities found" }

    before do
      allow(Glue).to receive(:notify) # suppress the output
      allow(Glue).to receive(:warn) # suppress the output

      # This acts as a guard against actually calling bundle-audit from the CLI.
      # (All specs should use canned responses instead.)
      allow(task).to receive(:runsystem) do
        puts "Warning from rspec -- make sure you're not attempting to call the actual bundle-audit API"
        puts "within an 'it' block with description '#{self.class.description}'"
        minimal_response
      end
    end

    context "with no Gemfile.lock file in root, and no sub-dirs" do
      let(:target) { 'no_findings_no_gemfile_lock' }
      subject(:task_findings) { task.findings }
      it { is_expected.to eq([]) }
    end

    context "with one Gemfile.lock in the root dir" do
      let(:raw_report) { get_raw_report(target) }

      before do
        allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(raw_report)
        task.run
        task.analyze
      end

      context "with no findings" do
        let(:target) { 'no_findings' }
        subject(:task_findings) { task.findings }
        it { is_expected.to eq([]) }
      end

      context "with one finding" do
        let(:finding) { task.findings.first }

        context "of unknown criticality" do
          let (:target) { 'finding_2_unknown' }

          it "has severity 2" do
            expect(finding.severity).to eq(2)
          end
        end

        context "of low criticality" do
          let (:target) { 'finding_1' }

          it "has severity 1" do
            expect(finding.severity).to eq(1)
          end
        end

        context "of medium criticality" do
          let (:target) { 'finding_2' }

          it "has severity 2" do
            expect(finding.severity).to eq(2)
          end
        end

        context "of high criticality" do
          let (:target) { 'finding_3' }

          it "has severity 3" do
            expect(finding.severity).to eq(3)
          end
        end
      end
    end
  end

 end
