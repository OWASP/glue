# rubocop:disable Metrics/BlockLength, Metrics/LineLength

require 'spec_helper'

require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/retirejs'

# TODO?: Move this to spec/spec_helper.rb:
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

describe Glue::RetireJS do
  # Run 'spec/tasks/retirejs/generate_reports.sh' to generate the reports
  # for any new 'targets' you want to test against.
  RETIREJS_TARGETS_PATH = 'spec/tasks/retirejs/targets'.freeze

  def get_retirejs(target = 'nil_target')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(RETIREJS_TARGETS_PATH, target)
    tracker = Glue::Tracker.new({})
    Glue::RetireJS.new(trigger, tracker)
  end

  def set_exclude_dir!(task, dir)
    tracker = task.instance_variable_get(:@tracker)
    tracker.options[:exclude_dirs] ||= []
    tracker.options[:exclude_dirs] << dir
  end

  def get_raw_report(target, subtarget = nil)
    path = File.join(get_target_path(target, subtarget), 'report.json')
    File.read(path).chomp
  end

  def get_target_path(target, subtarget = nil)
    if subtarget.nil?
      File.join(RETIREJS_TARGETS_PATH, target)
    else
      File.join(RETIREJS_TARGETS_PATH, target, subtarget)
    end
  end

  def cli_args(target, subtarget = nil)
    command_line = 'retire -c --outputpath /dev/stdout ' \
      "--outputformat json --path #{get_target_path(target, subtarget)}"
    [true, command_line]
  end

  describe '#initialize' do
    let(:task) { @task }
    before(:all) { @task = get_retirejs }

    it "sets the correct 'name'" do
      expect(task.name).to eq('RetireJS')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:code)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w[code javascript].to_set)
    end
  end

  describe '#supported?' do
    subject(:task) { get_retirejs }

    context "when 'runsystem' cannot run the task" do
      before do
        allow(Glue).to receive(:notify) # suppress the output
        allow(task).to receive(:supported_check_str).and_return('does/not/exist')
      end

      it { is_expected.not_to be_supported }

      it 'issues a notification' do
        expect(Glue).to receive(:notify)
        task.supported?
      end
    end

    context "when 'runsystem' returns a help-type message" do
      before do
        help_args = [anything, Glue::RetireJS::SUPPORTED_CHECK_STR]
        help_str = 'Usage: retire [options]'
        allow(task).to receive(:runsystem).with(*help_args).and_return(help_str)
      end

      it { is_expected.to be_supported }
    end
  end

  describe '#run' do
    # Note that 'runsystem' is always stubbed here (either with
    # 'allow' or 'expect') so the 'retire' cli won't actually be called.

    let(:task) { get_retirejs target }
    let(:minimal_response) { '[]' }

    before do
      allow(Glue).to receive(:notify) # suppress the output
    end

    context 'with no package.json file in root, and no sub-dirs' do
      let(:target) { 'no_findings_no_package_json' }

      it "does not call the 'retire' cli on the target" do
        expect(task).not_to receive(:runsystem).with(*cli_args(target))
        task.run
      end
    end

    context 'assuming valid (but minimal) reports' do
      context 'with one package.json in the root dir' do
        let(:target) { 'finding_1' }

        before do
          allow(task).to receive(:runsystem).with(*cli_args(target))
        end

        it 'passes the task name to Glue.notify' do
          expect(Glue).to receive(:notify).with(/^RetireJS/)
          task.run
        end

        it "calls the 'retire' cli once, from the root dir" do
          expect(task).to receive(:runsystem).with(*cli_args(target))
          task.run
        end

        it "returns 'self'" do
          expect(task.run).to be(task)
        end
      end

      context 'with one package.json in a sub-dir' do
        let(:target) { 'finding_1_nested' }
        let(:subtarget) { 'finding_1' }

        it "calls the 'retire' cli once, from the sub-dir" do
          expect(task).to receive(:runsystem).with(*cli_args(target, subtarget))
          task.run
        end
      end

      context 'with three package.json files in different sub-dirs' do
        let(:target) { 'findings_1_2_3' }
        let(:subtargets) { [1, 2, 3].map { |i| "finding_#{i}" } }

        context 'and no excluded dirs' do
          it "calls the 'retire' cli from each sub-dir" do
            subtargets.each do |subtarget|
              expect(task).to receive(:runsystem).with(*cli_args(target, subtarget))
            end
            task.run
          end
        end

        context 'and one excluded dir' do
          it "only calls the 'retire' cli from the non-excluded dirs" do
            set_exclude_dir!(task, subtargets[1])

            expect(task).not_to receive(:runsystem).with(*cli_args(target, subtargets[1]))
            expect(task).to receive(:runsystem).with(*cli_args(target, subtargets[0]))
            expect(task).to receive(:runsystem).with(*cli_args(target, subtargets[2]))

            task.run
          end
        end

        context 'and all dirs excluded' do
          it "does not call the 'retire' cli on the dirs" do
            subtargets.each do |subtarget|
              set_exclude_dir!(task, subtarget)
              expect(task).not_to receive(:runsystem).with(*cli_args(target, subtarget))
            end

            task.run
          end
        end
      end
    end

    context 'with a malformed report' do
      # The expected report format is a JSON-ified array, possibly empty.
      # But the 'run' method simply stores the raw output, it doesn't
      # do any parsing, so it won't raise anyway.

      let(:target) { 'malformed' }
      let(:malformed_response) { 'An example error message.' }

      before do
        allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(malformed_response)
      end

      it 'does not raise an exception' do
        expect { task.run }.not_to raise_error
      end
    end
  end

  describe '#analyze' do
    let(:task) { get_retirejs target }
    let(:minimal_response) { '[]' }

    before do
      allow(Glue).to receive(:notify) # suppress the output

      # This acts as a guard aginst actually calling the task from the CLI.
      # (All specs should use canned responses instead.)
      allow(task).to receive(:runsystem) do
        puts "Warning from rspec -- make sure you're not attempting to call the actual 'retire' API"
        puts "within a block with description '#{self.class.description}'"
        minimal_response
      end
    end

    context 'with no package.json file in root, and no sub-dirs' do
      let(:target) { 'no_findings_no_package_json' }
      subject(:task_findings) { task.run.analyze.findings }
      it { is_expected.to eq([]) }
    end

    context 'with one package.json in the root dir' do
      let(:raw_report) { get_raw_report(target) }

      before do
        allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(raw_report)
        task.run
        task.analyze
      end

      context 'with no findings' do
        let(:target) { 'no_findings' }
        subject(:task_findings) { task.findings }
        it { is_expected.to eq([]) }
      end

      context 'with one npm finding' do
        let(:finding) { task.findings.first }

        context 'of low severity' do
          let(:target) { 'finding_1' }
          let(:package) { 'cli-0.11.3' }

          it 'results in one finding' do
            expect(task.findings.size).to eq(1)
          end

          it 'has severity 1' do
            expect(finding.severity).to eq(1)
          end

          it "has the correct 'finding' descriptors" do
            description = "#{package} has known security issues"
            detail = 'https://nodesecurity.io/advisories/95'

            expect(finding.task).to eq('RetireJS')
            expect(finding.appname).to eq(target)
            expect(finding.description).to eq(description)
            expect(finding.detail).to eq(detail)
          end

          it "has the correct 'finding' source attribute" do
            source = {
              scanner: 'RetireJS',
              file: "retirejs-test->#{package}",
              line: nil,
              code: nil
            }

            expect(finding.source).to eq(source)
          end

          it 'has a self-consistent fingerprint' do
            fp = task.fingerprint("#{package}#{finding.source}#{finding.severity}#{finding.detail}")
            expect(finding.fingerprint).to eq(fp)
          end
        end

        context 'of medium severity' do
          let(:target) { 'finding_2' }

          it 'has severity 2' do
            expect(finding.severity).to eq(2)
          end
        end

        context 'of high severity' do
          let(:target) { 'finding_3' }

          it 'has severity 3' do
            expect(finding.severity).to eq(3)
          end
        end
      end

      context 'with three npm findings without implicit dependencies' do
        let(:target) { 'findings_123' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in 3 findings' do
          expect(findings.size).to eq(3)
        end

        it 'has severities 1, 2, and 3' do
          expect(findings.map(&:severity)).to eq([1, 2, 3])
        end
      end

      context 'with two npm findings one of which is implicit' do
        # The initial version of the task failed this one.
        #
        # The root package.json depends on 1.
        # Further, 1 depends on 2.
        #
        #  1
        #   \
        #    2

        let(:target) { 'findings_1-2' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in 2 unique findings' do
          expect(findings.size).to eq(2)
        end

        it 'has severities 1 and 2' do
          expect(findings.map(&:severity)).to eq([1, 2])
        end

        it 'has the correct number of vulnerable file paths per finding' do
          expect(task.findings[0].source[:file].split("\n").size).to eq(1)

          # This one fails, but it's a problem with 'retire', not with Glue:
          # expect(task.findings[1].source[:file].split("\n").size).to eq(1)
        end
      end

      context 'with three npm findings with implicit dependencies on 1' do
        # The initial version of the task failed this one.
        #
        # The root package.json depends on 1, 2, and 3.
        # Further, 2 depends on 1, and 3 depends on 1.
        #
        #  1     2     3
        #       /     /
        #      1     1

        let(:target) { 'findings_123_2-1_3-1' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in 3 unique findings' do
          expect(findings.size).to eq(3)
        end

        it 'has severities 1, 2, and 3' do
          expect(findings.map(&:severity)).to eq([1, 2, 3])
        end

        it 'has the correct number of vulnerable file paths per finding' do
          expect(task.findings[0].source[:file].split("\n").size).to eq(3)
          expect(task.findings[1].source[:file].split("\n").size).to eq(1)
          expect(task.findings[2].source[:file].split("\n").size).to eq(1)
        end
      end

      context 'with three npm findings with implicit deps on 1 and 2' do
        #  1 = cli
        #  2 = cookie-signature
        #  3 = pivottable
        #
        # In this example, the root package.json depends on 1, 2, and 3.
        # Further, 2 depends on 1, and 3 depends on 1 and 2.
        #
        #  1     2     3
        #       /     / \
        #      1     1   2
        #               /
        #              1
        #
        # Retire reports 7 results (one per node).
        # Glue should only report the 3 unique findings,
        # keeping track of all dependency paths for each.

        let(:target) { 'findings_123_2-1_3-12' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in 3 unique findings' do
          expect(findings.size).to eq(3)
        end

        it 'has severities 1, 2, and 3' do
          expect(findings.map(&:severity)).to eq([1, 2, 3])
        end

        it 'has the correct number of vulnerable file paths per finding' do
          expect(task.findings[0].source[:file].split("\n").size).to eq(4)
          expect(task.findings[1].source[:file].split("\n").size).to eq(2)
          expect(task.findings[2].source[:file].split("\n").size).to eq(1)
        end
      end

      context 'with two npm findings for one package' do
        # 4 = uglify-js (has both a medium and a high issue)

        let(:target) { 'findings_4' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in 2 unique findings' do
          expect(findings.size).to eq(2)
        end

        it 'has severities 2 and 3' do
          expect(findings.map(&:severity)).to eq([2, 3])
        end
      end

      context 'with one (high) js finding' do
        let(:target) { 'finding_f1' } # the vuln is in file_1.js
        let(:findings) { task.findings }

        it 'results in one finding' do
          expect(findings.size).to eq(1)
        end

        it 'has severity 3' do
          expect(findings.map(&:severity)).to eq([3])
        end

        it 'includes the filename in source[:file]' do
          expect(findings.first.source[:file]).to match(/file_1.js/)
        end
      end

      context 'with one js finding in a subdirectory' do
        let(:target) { 'finding_f1_nested' }
        let(:findings) { task.findings }

        it 'results in one finding' do
          expect(findings.size).to eq(1)
        end

        it 'includes the subdir/filename in source[:file]' do
          expect(findings.first.source[:file]).to match(%r{js_files\/file_1.js})
        end
      end

      context 'with the same js finding in two files' do
        let(:target) { 'findings_f1f1' }
        let(:findings) { task.findings }

        it 'results in one unique finding' do
          expect(findings.size).to eq(1)
        end

        it 'includes both filenames in source[:file]' do
          expect(findings.first.source[:file]).to match(/file_1.js/)
          expect(findings.first.source[:file]).to match(/file_2.js/)
        end
      end

      context 'with two js findings (low and high) in one file (difft js libs)' do
        let(:target) { 'findings_f12' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in two findings' do
          expect(findings.size).to eq(2)
        end

        it 'has severities 1 and 3' do
          expect(findings.map(&:severity)).to eq([1, 3])
        end

        it 'includes the same filename in source[:file] for both findings' do
          expect(findings.first.source[:file]).to match(/file_12.js/)
          expect(findings.last.source[:file]).to match(/file_12.js/)
        end
      end

      context 'with two js findings (med and high) in one js lib (in one file)' do
        let(:target) { 'findings_f3' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in two findings' do
          expect(findings.size).to eq(2)
        end

        it 'has severities 2 and 3' do
          expect(findings.map(&:severity)).to eq([2, 3])
        end

        it 'includes the same filename in source[:file] for both findings' do
          expect(findings.first.source[:file]).to match(/file_3.js/)
          expect(findings.last.source[:file]).to match(/file_3.js/)
        end
      end

      context 'with two js findings across two files (low in one, high in the other)' do
        let(:target) { 'findings_f1f2' } # high in file_1.js, low in file_2.js
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in two findings' do
          expect(findings.size).to eq(2)
        end

        it 'has severities 1 and 3' do
          expect(findings.map(&:severity)).to eq([1, 3])
        end

        it 'includes the correct filenames in source[:file]' do
          expect(findings.first.source[:file]).to match(/file_2.js/)
          expect(findings.last.source[:file]).to match(/file_1.js/)
        end
      end

      context 'with one (low) npm and one (high) js finding' do
        let(:target) { 'findings_1f1' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in two findings' do
          expect(findings.size).to eq(2)
        end

        it 'has severities 1 and 3' do
          expect(findings.map(&:severity)).to eq([1, 3])
        end

        it 'includes the correct indicators in source[:file]' do
          expect(findings.first.source[:file]).to match(/cli-0.11.3/)
          expect(findings.last.source[:file]).to match(/file_1.js/)
        end
      end

      context 'with npm package and js lib with same name/version and mult vulns each' do
        # jQuery v1.8.0: three npm vulns (med, high, high) and two js vulns (med, med)

        let(:target) { 'findings_5f5' }
        let(:findings) { task.findings.sort_by(&:severity) }

        it 'results in five findings' do
          expect(findings.size).to eq(5)
        end

        it 'has the correct severities' do
          expect(findings.map(&:severity)).to eq([2, 2, 2, 3, 3])
        end

        it 'has a difft fingerprint for each finding' do
          expect(findings.map(&:fingerprint).uniq.size).to eq(5)
        end
      end
    end

    context 'with three package.json files in different sub-dirs' do
      let(:target) { 'findings_1_2_3' }
      let(:args) { [1, 2, 3].map { |i| cli_args(target, "finding_#{i}") } }
      let(:raw_reports) { [1, 2, 3].map { |i| get_raw_report(target, "finding_#{i}") } }
      let(:findings) { task.findings.sort_by(&:severity) }

      before do
        raw_reports.each_with_index do |raw_report, i|
          allow(task).to receive(:runsystem).with(*args[i]).and_return(raw_report)
        end

        task.run
        task.analyze
      end

      it 'results in 3 findings' do
        expect(findings.size).to eq(3)
      end

      it 'has severities 1, 2, and 3' do
        expect(findings.map(&:severity)).to eq([1, 2, 3])
      end
    end

    context 'with malformed report' do
      before { allow(Glue).to receive(:warn) } # suppress the output

      context 'in the root dir' do
        let(:target) { 'malformed' }

        before do
          allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(malformed_response)
          task.run
        end

        context 'equal to nil' do
          # Would throw TypeError (trying to convert nil to a String):
          let(:malformed_response) { nil }

          it 'handles (does not raise) the error' do
            expect { task.analyze }.not_to raise_error
          end

          it "issues a notification matching 'Problem running RetireJS'" do
            expect(Glue).to receive(:notify).with(/Problem running RetireJS/)
            task.analyze
          end

          it "issues a warning matching 'Error'" do
            expect(Glue).to receive(:warn).with(/Error/)
            task.analyze
          end
        end

        context 'equal to an empty string' do
          # Would throw JSON::ParserError (attempting to parse ''):
          let(:malformed_response) { '' }

          it 'handles (does not raise) the error' do
            expect { task.analyze }.not_to raise_error
          end
        end

        context 'equal to a non-JSON string' do
          # Would throw JSON::ParserError:
          let(:malformed_response) { 'Example of a non-JSON string' }

          it 'handles (does not raise) the error' do
            expect { task.analyze }.not_to raise_error
          end
        end

        context 'equal to a non-array' do
          # Would throw NoMethodError (calling .has_key? on non-array):
          let(:malformed_response) { JSON.generate(results: true) }

          it 'handles (does not raise) the error' do
            expect { task.analyze }.not_to raise_error
          end
        end

        context 'with a crafted component name that leads to JsonPath error' do
          let(:malformed_response) do
            <<~HEREDOC
              [
                {
                  "results": [
                    {
                      "component": "\']",
                      "version": "0.11.3",
                    }
                  ]
                }
              ]
            HEREDOC
          end

          it 'handles (does not raise) the error' do
            expect { task.analyze }.not_to raise_error
          end

          it "issues a warning matching 'Error'" do
            expect(Glue).to receive(:warn).with(/Error/)
            task.analyze
          end
        end
      end

      context 'in a sub-dir, sibling to well-formed findings' do
        let(:target) { 'malformed_nested' }
        let(:sub_1_good) { 'finding_1' }
        let(:sub_2_bad) { 'malformed' }
        let(:sub_3_good) { 'zz_finding_1' }

        let(:raw_report_1) { get_raw_report(target, sub_1_good) }
        let(:malformed_response) { '' }
        let(:raw_report_3) { get_raw_report(target, sub_3_good) }

        before do
          allow(task).to receive(:runsystem).with(*cli_args(target, sub_1_good)).and_return(raw_report_1)
          allow(task).to receive(:runsystem).with(*cli_args(target, sub_2_bad)).and_return(malformed_response)
          allow(task).to receive(:runsystem).with(*cli_args(target, sub_3_good)).and_return(raw_report_3)
          task.run
        end

        it 'only issues one warning' do
          expect(Glue).to receive(:warn).with(/Error/).once
          task.analyze
        end

        it "results in 2 findings (doesn't exit early)" do
          # If it had exited early, we'd only have one finding.
          task.analyze
          expect(task.findings.size).to eq(2)
        end
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength, Metrics/LineLength
