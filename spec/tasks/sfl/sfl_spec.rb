require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/sfl'

describe Glue::SFL do
  SFL_TARGETS_PATH = 'spec/tasks/sfl/targets'

  def get_sfl(target = 'nil_target')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(SFL_TARGETS_PATH, target)
    tracker = Glue::Tracker.new({})
    Glue::SFL.new(trigger, tracker)
  end

  before do
    # Since this is cached at the class-level, need to
    # clear it out by hand between tests.
    if Glue::SFL.instance_variable_defined?(:@patterns)
      Glue::SFL.remove_instance_variable(:@patterns)
    end
  end

  describe "#initialize" do
    let(:task) { @task }
    before(:all) { @task = get_sfl }

    it "sets the correct 'name'" do
      expect(task.name).to eq('SFL')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:code)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w[code].to_set)
    end
  end

  describe "#supported?" do
    # Since the SFL analysis is built in to Glue (ie, not an external tool)
    # the '.supported?' method should always return 'true'.
    subject(:task) { get_sfl }
    it { is_expected.to be_supported }
  end

  describe "#run" do
    let(:task) { get_sfl target }
    before { allow(Glue).to receive(:notify) } # prevents printing to screen

    context "with a bad patterns file" do
      def overwrite_patterns_path(bad_patterns)
        @orig_patterns_path = Glue::SFL::PATTERNS_FILE_PATH.dup
        new_path = File.join(File.dirname(SFL_TARGETS_PATH), bad_patterns)
        Glue::SFL::PATTERNS_FILE_PATH.replace new_path
      end

      def restore_patterns_path
        Glue::SFL::PATTERNS_FILE_PATH.replace @orig_patterns_path
      end

      let(:target) { 'no_findings' }
      before { allow(Glue).to receive(:warn) } # prevents printing to screen

      context "due to an invalid path" do
        before(:all) { overwrite_patterns_path 'non-existent-path' }
        after(:all) { restore_patterns_path }

        it "handles (does not raise) the error" do
          expect { task.run }.not_to raise_error
        end

        it "issues a notification matching 'Problem running SFL'" do
          expect(Glue).to receive(:notify).with(/Problem running SFL/)
          task.run rescue nil
        end

        it "issues a warning matching 'Err'" do
          expect(Glue).to receive(:warn).with(/Err/)
          task.run rescue nil
        end
      end

      context "due to malformatted JSON" do
        before(:all) { overwrite_patterns_path 'malformed_patterns_file.json' }
        after(:all) { restore_patterns_path }

        it "handles (does not raise) the error" do
          expect { task.run }.not_to raise_error
        end

        it "issues a notification matching 'Problem running SFL'" do
          expect(Glue).to receive(:notify).with(/Problem running SFL/)
          task.run rescue nil
        end

        it "issues a warning matching 'JSON::ParserError'" do
          expect(Glue).to receive(:warn).with(/JSON::ParserError/)
          task.run rescue nil
        end
      end
    end

    context "in a general context" do
      let(:target) { 'no_findings' }

      it "passes the task name to Glue.notify" do
        expect(Glue).to receive(:notify).with(/^SFL/)
        task.run
      end

      it "returns 'self'" do
        expect(task.run).to be(task)
      end
    end
  end

  describe "#analyze" do
    let(:task) { get_sfl target }

    before do
      allow(Glue).to receive(:notify) # stub to prevent printing to screen
      task.run
      task.analyze
    end

    context "with zero findings" do
      subject(:task_findings) { task.findings }

      context "in an empty dir" do
        let(:target) { 'no_findings_empty_dir' }
        it { is_expected.to eq([]) }
      end

      context "in a non-empty dir" do
        let(:target) { 'no_findings' }
        it { is_expected.to eq([]) }
      end

      context "with a sub-dir named 'password'" do
        # The point is that we are only interested in checking
        # file names (possibly with their paths) and extensions,
        # but not directory names.
        #
        # A file named 'password' would be flagged,
        # but a directory named 'password' should not be flagged.

        let(:target) { 'no_findings_password_subdir' }
        it { is_expected.to eq([]) }
      end
    end

    context "with one finding" do
      # Doesn't seem necessary to check the 'finding' details
      # in every case here, so it's only done once.
      #
      # The main point is to make sure the different types of
      # patterns all work.

      subject(:findings_count) { task.findings.size }

      context "on an extension exact match" do
        let(:target) { 'one_finding_extension_match' }
        it { is_expected.to eq(1) }
      end

      context "on an extension regex match" do
        let(:target) { 'one_finding_extension_regex' }
        it { is_expected.to eq(1) }
      end

      context "on a path regex match" do
        let(:target) { 'one_finding_path_regex' }
        it { is_expected.to eq(1) }
      end

      context "on a filename regex match" do
        let(:target) { 'one_finding_filename_regex' }
        it { is_expected.to eq(1) }
      end

      context "on a filename exact match" do
        # The filename here is 'secret_token.rb'.
        let(:target) { 'one_finding_filename_match' }
        let(:finding) { task.findings.first }

        let(:filepath) do
          File.join(SFL_TARGETS_PATH, target, 'secret_token.rb')
        end

        let(:the_pattern) do
          # Copy-pasted from the patterns file:
          {
            "part": "filename",
            "type": "match",
            "pattern": "secret_token.rb",
            "caption": "Ruby On Rails secret token configuration file",
            "description": "If the Rails secret token is known, " \
                           "it can allow for remote code execution. " \
                           "(http://www.exploit-db.com/exploits/27527/)"
          }
        end

        it { is_expected.to eq(1) }

        it "has the correct 'finding' descriptors" do
          expect(finding.task).to eq("SFL")
          expect(finding.appname).to eq(target)
          expect(finding.description).to eq(the_pattern[:caption])
          expect(finding.detail).to eq(the_pattern[:description])
        end

        it "has the filepath in its 'source'" do
          expect(finding.source).to match(filepath)
        end

        it "has the expected fingerprint" do
          fprint_input = "SFL-#{the_pattern[:part]}#{the_pattern[:type]}" \
                         "#{the_pattern[:pattern]}#{filepath}"
          the_fingerprint = task.fingerprint(fprint_input)

          expect(finding.fingerprint).to eq(the_fingerprint)
        end
      end
    end

    context "with two findings" do
      subject(:findings_count) { task.findings.size }

      context "in the same dir" do
        let(:target) { 'two_findings' }
        it { is_expected.to eq(2) }
      end

      context "in different dirs" do
        let(:target) { 'two_findings_difft_dirs' }
        it { is_expected.to eq(2) }
      end

      context "for a single file path" do
        let(:target) { 'two_findings_one_file' }

        it { is_expected.to eq(2) }

        it "has different fingerprints for the two findings" do
          # This makes sure the fingerprint is based on more than just the
          # file path (since the same file path can trigger more than one match)
          fprint1 = task.findings.first.fingerprint
          fprint2 = task.findings.last.fingerprint

          expect(fprint1).not_to eq(fprint2)
        end
      end
    end
  end

  describe "::patterns" do
    # The patterns file itself is tested in a separate test suite.

    subject(:patterns) { Glue::SFL.patterns }

    it { is_expected.to be_an_instance_of(Array) }

    # The point here is that .patterns should return a clone
    # of the internal @patterns class-variable:
    it { is_expected.to eq(Glue::SFL.instance_variable_get(:@patterns)) }
    it { is_expected.not_to be(Glue::SFL.instance_variable_get(:@patterns)) }
  end

  # The "::matches?" method was tested implicitly in the tests for "#analyze"
  # (all of the allowed combinations were included there)
  # so no explicit tests for it are done here.
end
