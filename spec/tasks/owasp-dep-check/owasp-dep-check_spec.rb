require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/owasp-dep-check'


describe Glue::OWASPDependencyCheck do

  DEP_CHECK_TARGETS_PATH = 'spec/tasks/owasp-dep-check/targets'

  def get_dep_check (target = 'nil_target')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(DEP_CHECK_TARGETS_PATH, target)
    tracker = Glue::Tracker.new({})
    @dep_check_path = tracker.options[:owasp_dep_check_path]
    Glue::OWASPDependencyCheck.new(trigger, tracker)
  end

  def get_raw_report (target, subtarget = nil)
    path = File.join(get_target_path(target, subtarget), "dependency-check-report.xml")
    File.read(path).chomp
  end

  def get_target_path (target, subtarget = nil)
    if subtarget.nil?
      File.join(DEP_CHECK_TARGETS_PATH, target)
    else
      File.join(DEP_CHECK_TARGETS_PATH, target, subtarget)
    end
  end

  def cli_args (target, subtarget = nil)
    target_path = get_target_path(target, subtarget)
    [true, @dep_check_path, "--project", "Glue", "-f", "ALL", "-out", target_path, "-s", target_path]
  end

  describe "#initialize" do
    let(:task) { @task }
    before(:all) { @task = get_dep_check }

    it "sets the correct 'name'" do
      expect(task.name).to eq('OWASP Dependency Check')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:code)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w(code java .net).to_set)
    end
  end

  describe "#supported?" do
    subject(:task) { get_dep_check }

    context "when 'runsystem' cannot run the task" do
      before do
        allow(Glue).to receive(:notify)
        cmd_args = [true, @dep_check_path, "-v"]
        cmd_str = 'command not found'
        allow(task).to receive(:runsystem).with(*cmd_args).and_return(cmd_str)
      end

      it { is_expected.not_to be_supported }

      it 'issues a notification' do
        expect(Glue).to receive(:notify)
        task.supported?
      end
    end

    context "when 'runsystem' returns a version message" do
      before do
        allow(Glue).to receive(:notify)
        cmd_args = [true, @dep_check_path, "-v"]
        cmd_str = 'Dependency-Check Core version'
        allow(task).to receive(:runsystem).with(*cmd_args).and_return(cmd_str)
      end

      it { is_expected.to be_supported }

    end
  end

  describe "#run" do
    let(:task) { get_dep_check target }
    let(:minimal_response) { "No vulnerabilities found" }

    before do
      allow(Glue).to receive(:notify)
      allow(Glue).to receive(:warn)

      allow(task).to receive(:runsystem) do
        minimal_response
      end
    end

    context "with one JAR file in the root directory" do
      let(:target) { 'findings_1' }

      before do
        allow(task).to receive(:runsystem).with(*cli_args(target))
      end

      it 'passes the task name to Glue.notify' do
        expect(Glue).to receive(:notify).with(/OWASP Dependency Check/)
        task.run
      end

      it "calls the 'owaspdependencycheck' cli once, from the root directory" do
        expect(task).to receive(:runsystem).with(*cli_args(target))
        task.run
      end
    end

    context "with one JAR file in a sub-directory" do
      let(:target) { 'findings_1_nested' }
      let(:subtarget) { 'findings_1' }

      it "calls the 'owaspdependencycheck' cli once, from the root directory" do
        expect(task).not_to receive(:runsystem).with(*cli_args(target, subtarget))
        expect(task).to receive(:runsystem).with(*cli_args(target))
        task.run
      end
    end

  end

  describe "#analyze" do
    let(:task) { get_dep_check target }
    let(:minimal_response) { '[]' }

    before do
      allow(Glue).to receive(:notify)
      allow(Glue).to receive(:warn)
      allow(STDOUT).to receive(:puts)

      allow(task).to receive(:runsystem) do
        minimal_response
      end
    end

    context "with one JAR file in the root directory" do
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

      context "with 10 findings" do
        let(:target) { 'findings_2' }

        it 'results in 10 findings' do
          expect(task.findings.size).to eq(10)
        end

        it 'has severities 3, 3, 2, 1, 3, 2, 2, 2, 2, and 2' do
          expect(task.findings.map(&:severity)).to eq([3, 3, 2, 1, 3, 2, 2, 2, 2, 2])
        end
      end
    end

  end

end
