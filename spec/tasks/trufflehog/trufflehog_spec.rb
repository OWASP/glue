require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/trufflehog'

describe Glue::Trufflehog do
  # Run 'spec/tasks/trufflehog/generate_reports.sh' to generate the reports
  # for any new 'targets' you want to test against.
  TARGETS_PATH = 'spec/tasks/trufflehog/targets'
  REPORTS_PATH = 'spec/tasks/trufflehog/reports'

  def get_trufflehog(target = 'nil_target')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(TARGETS_PATH, target)
    Glue::Trufflehog.new(trigger, nil)
  end

  def get_expected_result(target)
    File.read(File.join(REPORTS_PATH, "#{target}.json")).chomp
  end

  describe "#initialize" do
    let(:task) { @task }
    before(:all) { @task = get_trufflehog }

    it "sets the correct 'name'" do
      expect(task.name).to eq('Trufflehog')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:code)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w(code java .net).to_set)
    end

    it "sets the correct '@trufflehog_path'" do
      path = '/home/glue/tools/truffleHog/truffleHog/truffleHog.py'
      expect(task.instance_variable_get(:@trufflehog_path)).to eq(path)
    end
  end

  describe "#supported?" do
    let(:task) { get_trufflehog }

    it "matches the output of File.exist?(@trufflehog_path)" do
      # path = '/home/glue/tools/truffleHog/truffleHog/truffleHog.py'
      path = task.instance_variable_get(:@trufflehog_path)
      expect(task.supported?).to eq(File.exist? path)
    end

    context "when @trufflehog_path points to a non-existent path" do
      let(:bogus_path) { "/xxx_non_existent_directory_xxx" }

      before do
        allow(Glue).to receive(:notify) # stub Glue.notify to prevent printing to screen
        task.instance_variable_set(:@trufflehog_path, bogus_path)
      end

      it "returns false" do
        expect(task).not_to be_supported
      end

      it "issues a notification" do
        expect(Glue).to receive(:notify)
        task.supported?
      end
    end
  end

  describe "#run" do
    before { allow(Glue).to receive(:notify) } # suppresses the output

    it "passes the task name to Glue.notify" do
      expect(Glue).to receive(:notify).with('Trufflehog')
      get_trufflehog('-h').run # returns Trufflehog's help message
    end

    context "when run on a target" do
      let(:task) { get_trufflehog target }
      let (:expected_result) { get_expected_result target }
      before { task.run}
      subject(:task_result) { task.result }

      context "with zero findings" do
        let(:target) { 'zero_findings' }
        it { is_expected.to eq(expected_result) }
      end

      context "with one finding" do
        let(:target) { 'one_finding' }
        it { is_expected.to eq(expected_result) }
      end

      context "with multiple nested findings" do
        let(:target) { 'mult_findings' }
        it { is_expected.to eq(expected_result) }
      end
    end
  end

  describe "#analyze" do
    def create_finding(target, source, secret)
      {
        'appname' =>  target,
        'description' =>  "Possible password or other secret in source code.",
        'detail' =>  "Apparent password or other secret: #{secret}",
        'source' =>  source,
        'severity' =>  4,
        'fingerprint' =>  "Trufflehog|#{source}",
        'task' =>  'Trufflehog'
      }
    end

    context "with a well-formatted result" do
      let(:task) { get_trufflehog target }
      let (:result) { get_expected_result target }
      subject(:task_findings) { task.findings }

      before do
        task.result = result
        task.analyze
      end

      context "with zero findings" do
        let(:target) { 'zero_findings' }
        it { is_expected.to eq([]) }
      end

      context "with one finding" do
        let(:target) { 'one_finding' }

        it "results in one finding" do
          expect(task_findings.size).to eq(1)
        end

        it "produces the expected finding" do
          source, secret = JSON.parse(result).first
          expected_finding = create_finding(target, source, secret)

          actual_finding = JSON.parse(task_findings.first.to_json)
          actual_finding.delete 'timestamp'

          expect(actual_finding).to eq(expected_finding)
        end
      end

      context "with multiple findings" do
        let(:target) { 'mult_findings' }

        it "results in the correct number of findings" do
          expected_size = JSON.parse(result).size
          expect(task_findings.size).to eq(expected_size)
        end
      end
    end

    context "with malformed result equal to" do
      let(:task) { get_trufflehog }

      before do
        allow(Glue).to receive(:notify) # suppresses the output
        task.result = result
      end

      context "nil" do
        let(:result) { nil }

        it "raises a TypeError" do
          expect { task.analyze }.to raise_error(TypeError)
        end

        it "issues a notification involving 'Trufflehog'" do
          expect(Glue).to receive(:notify).with(/Trufflehog/)
          task.analyze rescue nil
        end
      end

      context "empty string" do
        let(:result) { '' }

        it "raises a JSON::ParserError" do
          expect { task.analyze }.to raise_error(JSON::ParserError)
        end
      end

      context "non-JSON" do
        let(:result) { 'some_key  some_value' }

        it "raises a JSON::ParserError" do
          expect { task.analyze }.to raise_error(JSON::ParserError)
        end
      end
    end
  end
end
