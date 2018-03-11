require 'spec_helper'
require 'addressable/template'
require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/zap'


# TODO?: Move this to spec/spec_helper.rb:
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

describe Glue::Zap do
  # Run 'spec/tasks/snyk/generate_reports.sh' to generate the reports
  # for any new 'targets' you want to test against.
  SNYK_TARGETS_PATH = 'spec/tasks/snyk/targets'

  def get_zap(target = 'nil_target')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(SNYK_TARGETS_PATH, target)
    tracker = Glue::Tracker.new({})
    Glue::Zap.new(trigger, tracker)
  end

  def set_zap_params!(zap_task, host, port, api_key)
    tracker = zap_task.instance_variable_get(:@tracker)
    tracker.options[:zap_api_token] = api_key
    tracker.options[:zap_host] = host
    tracker.options[:zap_port] = port
  end

  def enable_passive_mode(zap_task)
    tracker = zap_task.instance_variable_get(:@tracker)
    tracker.options[:zap_passive_mode] = true
  end

  def get_raw_report(target, subtarget = nil)
    path = File.join(get_target_path(target, subtarget), "report.json")
    File.read(path).chomp
  end

  def get_target_path(target, subtarget = nil)
    if subtarget.nil?
      File.join(SNYK_TARGETS_PATH, target)
    else
      File.join(SNYK_TARGETS_PATH, target, subtarget)
    end
  end

  def cli_args(target, subtarget = nil)
    [true, "snyk", "test", "--json", { chdir: get_target_path(target, subtarget) }]
  end

  describe "#initialize" do
    let(:task) { @task }
    before(:all) { @task = get_zap }

    it "sets the correct 'name'" do
      expect(task.name).to eq('ZAP')
    end

    it "sets the correct 'stage'" do
      expect(task.stage).to eq(:live)
    end

    it "sets the correct 'labels'" do
      expect(task.labels).to eq(%w(live).to_set)
    end
  end

  describe "#supported?" do

    subject(:task) { get_zap }

    context "when Zap version is not supported" do
      before do
        set_zap_params!(subject, "http://zap", 1234, "key")
        uriTemplate = Addressable::Template.new "http://zap:1234/JSON/core/view/version/?apikey=key"
        stub_request(:get, uriTemplate)
            .to_return(body: "{\"version\":\"2.7.0\"}", status: 200,
            headers: { 'Content-Length' => 19 })
        allow(Glue).to receive(:notify) # stub Glue.notify to prevent printing to screen
      end

      it { is_expected.not_to be_supported }

      it "issues a notification" do
        
        expect(Glue).to receive(:notify)
        task.supported?
      end
    end

    context "when Zap is not available" do
      before do
        set_zap_params!(subject, "http://zap", 1234, "key")
        allow(Glue).to receive(:error) # stub Glue.notify to prevent printing to screen
      end

      it { is_expected.not_to be_supported }

      it "issues an error" do
        
        expect(Glue).to receive(:error)
        task.supported?
      end
    end

    context "when Zap is available" do
      before do
        set_zap_params!(subject, "http://zap", 1234, "key")
        stub_request(:any, "http://zap:1234/JSON/core/view/version/").
            to_return(body: "{\"version\":\"2.6.0\"}", status: 200,
            headers: { 'Content-Length' => 19 })
        allow(Glue).to receive(:notify) # stub Glue.notify to prevent printing to screen
      end

      it { is_expected.to be_supported }
    end

  end

   describe "#run" do
    subject(:task) { get_zap }

    before do
      set_zap_params!(subject, "http://zap", 1234, "key")
      allow(Glue).to receive(:notify) # stub Glue.notify to prevent printing to screen
    end

    context "when using pasive mode" do
      before do
        enable_passive_mode(subject)
      end

      it "should work" do
        stub_request(:any, "http://zap:1234/JSON/pscan/view/recordsToScan/").
          to_return(body: "{\"recordsToScan\":\"0\"}", status: 200,
          headers: { 'Content-Length' => 21})

        stub_request(:any, "http://zap:1234/JSON/core/view/alerts/").
          to_return(body: "{\"recordsToScan\":\"0\"}", status: 200,
          headers: { 'Content-Length' => 21})
        task.run
      end
    end
   end

#     before do
#       allow(Glue).to receive(:notify) # suppress the output

#       # This acts as a guard aginst actually calling Snyk from the CLI.
#       # (All specs should use canned responses instead.)
#       allow(task).to receive(:runsystem) do
#         puts "Warning from rspec -- make sure you're not attempting to call the actual Snyk API"
#         puts "within an 'it' block with description '#{self.class.description}'"
#         minimal_response
#       end
#     end

#     context "with no package.json file in root, and no sub-dirs" do
#       let(:target) { 'no_findings_no_package_json' }

#       it "does not call the Snyk cli on the target" do
#         expect(task).not_to receive(:runsystem).with(*cli_args(target))
#         task.run
#       end
#     end

#     context "assuming valid (but minimal) snyk reports" do
#       # Expectations like the following:
#       #
#       #   expect(task).to receive(:runsystem).with(*cli_args(target)).and_return(minimal_response)
#       #   task.run
#       #
#       # can be read as:
#       # 'When we call task.run, we expect it to call:
#       #    runsystem([true, "snyk", "test", "--json", { chdir: <target> }])
#       #  When it does, have it return a canned response, instead of the default response
#       #  for stubbed methods (nil).'
#       #  Ie, the response is not part of the expectation. It's needed, b/c without it 'runsystem'
#       #  will return nil, and task.run may raise an exception (since it expects a non-nil response).

#       context "with one package.json in the root dir" do
#         let(:target) { 'finding_1' }

#         it "passes the task name to Glue.notify" do
#           allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(minimal_response)
#           expect(Glue).to receive(:notify).with(/^Snyk/)
#           task.run
#         end

#         it "calls the Snyk cli once, from the root dir" do
#           expect(task).to receive(:runsystem).with(*cli_args(target)).and_return(minimal_response)
#           task.run
#         end
#       end

#       context "with one package.json in a sub-dir" do
#         let(:target) { 'finding_1_nested' }
#         let(:subtarget) { 'finding_1' }

#         it "calls the Snyk cli once, from the sub-dir" do
#           expect(task).to receive(:runsystem).with(*cli_args(target, subtarget)).and_return(minimal_response)
#           task.run
#         end
#       end

#       context "with three package.json files in different sub-dirs" do
#         let(:target) { 'findings_1_2_3' }
#         let(:subtargets) { [1, 2, 3].map { |i| "finding_#{i}" } }

#         context "and no excluded dirs" do
#           it "calls the Snyk cli from each sub-dir" do
#             subtargets.each do |subtarget|
#               expect(task).to receive(:runsystem).with(*cli_args(target, subtarget)).and_return(minimal_response)
#             end
#             task.run
#           end
#         end

#         context "and one excluded dir" do
#           it "only calls the Snyk cli from the non-excluded dirs" do
#             set_exclude_dir!(task, subtargets[1])

#             expect(task).not_to receive(:runsystem).with(*cli_args(target, subtargets[1]))
#             expect(task).to receive(:runsystem).with(*cli_args(target, subtargets[0])).and_return(minimal_response)
#             expect(task).to receive(:runsystem).with(*cli_args(target, subtargets[2])).and_return(minimal_response)

#             task.run
#           end
#         end

#         context "and all dirs excluded" do
#           it "does not call the Snyk cli on the dirs" do
#             subtargets.each do |subtarget|
#               set_exclude_dir!(task, subtarget)
#               expect(task).not_to receive(:runsystem).with(*cli_args(target, subtarget))
#             end

#             task.run
#           end
#         end
#       end
#     end

#     context "with a malformed report" do
#       # The expected report format is a JSON-ified hash with a 'vulnerabilities' key:
#       # JSON.parse(raw_output)["vulnerabilities"]

#       before { allow(Glue).to receive(:warn) } # stub to prevent printing to screen

#       context "in the root dir" do
#         let(:target) { 'malformed' }

#         before do
#           allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(malformed_response)
#         end

#         context "equal to non-JSON" do
#           let(:malformed_response) { 'An example error message that could result from running Snyk.' }

#           it "handles (does not raise) the JSON::ParserError" do
#             expect { task.run }.not_to raise_error
#           end

#           it "issues a notification matching 'Problem running Snyk'" do
#             expect(Glue).to receive(:notify).with(/Problem running Snyk/)
#             task.run rescue nil
#           end

#           it "issues a warning matching 'JSON::ParserError'" do
#             expect(Glue).to receive(:warn).with(/JSON::ParserError/)
#             task.run rescue nil
#           end
#         end

#         context "equal to a JSON array (instead of a hash)" do
#           # Would raise a TypeError if not rescued.
#           let(:malformed_response) { JSON.generate([1, 2, 3]) }

#           it "doesn't raise an error" do
#             expect { task.run }.not_to raise_error
#           end
#         end

#         context "equal to an empty JSON hash" do
#           # Normally this won't raise an error --
#           # you simply end up with 'nil' when you access a non-existent key
#           let(:malformed_response) { JSON.generate({}) }

#           it "doesn't raise an error" do
#             expect { task.run }.not_to raise_error
#           end
#         end
#       end

#       context "in a sub-dir, sibling to well-formed findings" do
#         # The point here is that 'task.run' is running an 'each' loop
#         # over the directories. If one directory fails, we don't want that
#         # to stop the other directories from being processed.

#         let(:target) { 'malformed_nested'}
#         let(:sub_1_good) { 'finding_1' }
#         let(:sub_2_bad) { 'malformed' }
#         let(:sub_3_good) { 'zz_finding_1' }

#         let(:malformed_response) { 'An example error message.' }

#         before do
#           allow(task).to receive(:runsystem).with(*cli_args(target, sub_1_good)).and_return(minimal_response)
#           allow(task).to receive(:runsystem).with(*cli_args(target, sub_2_bad)).and_return(malformed_response)
#           allow(task).to receive(:runsystem).with(*cli_args(target, sub_3_good)).and_return(minimal_response)
#         end

#         it "only issues one warning" do
#           expect(Glue).to receive(:warn).with(/JSON::ParserError/).once
#           task.run rescue nil
#         end

#         it "calls Snyk on all the sub-dirs (doesn't exit early)" do
#           expect(task).to receive(:runsystem).with(*cli_args(target, sub_1_good))
#           expect(task).to receive(:runsystem).with(*cli_args(target, sub_2_bad))
#           expect(task).to receive(:runsystem).with(*cli_args(target, sub_3_good))
#           task.run rescue nil
#         end
#       end
#     end
#   end

#   describe "#analyze" do
#     let(:task) { get_snyk target }
#     let(:minimal_response) { "{\"vulnerabilities\": []}" }

#     before do
#       allow(Glue).to receive(:notify) # suppress the output

#       # This acts as a guard aginst actually calling Snyk from the CLI.
#       # (All specs should use canned responses instead.)
#       allow(task).to receive(:runsystem) do
#         puts "Warning from rspec -- make sure you're not attempting to call the actual Snyk API"
#         puts "within an 'it' block with description '#{self.class.description}'"
#         minimal_response
#       end
#     end

#     context "with no package.json file in root, and no sub-dirs" do
#       let(:target) { 'no_findings_no_package_json' }
#       subject(:task_findings) { task.findings }
#       it { is_expected.to eq([]) }
#     end

#     context "with one package.json in the root dir" do
#       let(:raw_report) { get_raw_report(target) }

#       before do
#         allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(raw_report)
#         task.run
#         task.analyze
#       end

#       context "with no findings" do
#         let(:target) { 'no_findings' }
#         subject(:task_findings) { task.findings }
#         it { is_expected.to eq([]) }
#       end

#       context "with one finding" do
#         let(:raw_result) { JSON.parse(raw_report)["vulnerabilities"].first }
#         let(:finding) { task.findings.first }

#         context "of low severity" do
#           let(:target) { 'finding_1' }

#           it "results in one finding" do
#             expect(task.findings.size).to eq(1)
#           end

#           it "has severity 1" do
#             expect(finding.severity).to eq(1)
#           end

#           it "has the correct 'finding' descriptors" do
#             description = "#{raw_result['name']}@#{raw_result['version']} - #{raw_result['title']}"

#             expect(finding.task).to eq("Snyk")
#             expect(finding.appname).to eq(target)
#             expect(finding.description).to eq(description)
#           end

#           it "has well-formatted html in its 'detail' attribute" do
#             expect(Nokogiri::HTML(finding.detail).errors).to be_empty
#           end

#           it "has the correct 'finding' source attribute" do
#             upgrade_paths = "Upgrade Path:\n"
#             raw_result['upgradePath'].each_with_index do |upgrade_path, i|
#               upgrade_paths << "\n#{raw_result['from'][i]} -> #{upgrade_path}"
#             end

#             source = {
#               scanner: "Snyk",
#               file: raw_result['from'].join('->'),
#               line: nil,
#               code: upgrade_paths
#             }

#             expect(finding.source).to eq(source)
#           end

#           it "has a self-consistent fingerprint" do
#             fp = task.fingerprint("#{finding.description}#{finding.detail}#{finding.source}#{finding.severity}")
#             expect(finding.fingerprint).to eq(fp)
#           end
#         end

#         context "of medium severity" do
#           let (:target) { 'finding_2' }

#           it "has severity 2" do
#             expect(finding.severity).to eq(2)
#           end

#           it "has well-formatted html in its 'detail' attribute" do
#             expect(Nokogiri::HTML(finding.detail).errors).to be_empty
#           end
#         end

#         context "of high severity" do
#           let (:target) { 'finding_3' }

#           it "has severity 3" do
#             expect(finding.severity).to eq(3)
#           end

#           it "has well-formatted html in its 'detail' attribute" do
#             expect(Nokogiri::HTML(finding.detail).errors).to be_empty
#           end
#         end
#       end

#       context "with several findings in a non-trivial dependency structure" do
#         #  1 = cli ( = findings[0] )
#         #  2 = cookie-signature
#         #  3 = pivottable
#         #
#         # In this example, the root package.json depends on 1, 2, and 3.
#         # Further, 2 depends on 1, and 3 depends on 2 (and so implicitly on 1).
#         #
#         #  1     2     3
#         #       /     / \
#         #      1     1   2
#         #               /
#         #              1
#         #
#         # Snyk reports 7 vulnerabilities, with 3 unique id's.
#         # Glue should only report the 3 unique findings,
#         # keeping track of all dependency paths for each.

#         let(:target) { 'findings_123_2-1_3-12' }
#         let(:raw_result) { JSON.parse(raw_report)["vulnerabilities"] }
#         let(:findings) { task.findings }

#         it "results in 3 findings" do
#           expect(task.findings.size).to eq(3)
#         end

#         it "contains the upgrade paths for each finding" do
#           expect(task.findings[0].source[:code]).to match("cli@0.11.3 -> cli@1.0.0")
#           expect(task.findings[1].source[:code]).to match("cookie-signature@1.0.3 -> cookie-signature@1.0.4")
#           expect(task.findings[2].source[:code]).to match("pivottable@1.4.0 -> pivottable@2.0.0")
#         end

#         it "has the correct number of vulnerable file paths per finding" do
#           expect(task.findings[0].source[:file].split('<br>').size).to eq(4)
#           expect(task.findings[1].source[:file].split('<br>').size).to eq(2)
#           expect(task.findings[2].source[:file].split('<br>').size).to eq(1)
#         end
#       end

#       context "with snyk's sample data report" do
#         # The point here is to do a textual comparison of Glue's findings
#         # for a complicated report, comparing against a snapshot of itself.
#         #
#         # The raw report here is based on one that Snyk uses for testing.
#         # It's a mildly-edited version of:
#         #   https://github.com/snyk/snyk-to-html/blob/master/sample-data/test-report.json
#         #
#         # To generate the Glue findings snapshot, I simply added a binding.pry to the spec
#         # below and (in irb) dumped the .findings.to_json to the file 'findings_snapshot.json'.
#         # TODO?: Write a script to do this, if it needs to be regenerated.

#         def get_findings_snapshot(target)
#           path = File.join(get_target_path(target), "findings_snapshot.json")
#           JSON.parse(File.read(path).chomp).map { |finding_json| JSON.parse(finding_json) }
#         end

#         let(:target) { 'snyk-sample-data' }
#         let(:findings_snapshot) { get_findings_snapshot(target) }
#         # Convert the findings from 'Glue::Finding' objects to hashes:
#         subject(:findings) { task.findings.map { |finding| JSON.parse(finding.to_json) } }

#         it "matches a snapshot of the findings output" do
#           expect(findings.size).to eq(findings_snapshot.size)

#           findings.each_with_index do |finding, i|
#             snapshot = findings_snapshot[i]

#             snapshot.delete 'timestamp'
#             finding.delete 'timestamp'

#             expect(finding).to eq(snapshot)
#           end
#         end
#       end
#     end

#     context "with three package.json files in different sub-dirs" do
#       let(:target) { 'findings_1_2_3' }
#       let(:args) { [1, 2, 3].map { |i| cli_args(target, "finding_#{i}") } }
#       let(:raw_reports) { [1, 2, 3].map { |i| get_raw_report(target, "finding_#{i}") } }

#       before do
#         raw_reports.each_with_index do |raw_report, i|
#           allow(task).to receive(:runsystem).with(*args[i]).and_return(raw_report)
#         end
#         task.run
#         task.analyze
#       end

#       it "results in 3 findings" do
#         expect(task.findings.size).to eq(3)
#       end

#       it "has one file path per finding" do
#         task.findings.each do |finding|
#           expect(finding.source[:file].split('<br>').size).to eq(1)
#         end
#       end
#     end

#     context "with malformed 'vulnerabilities'" do
#       # The .run method already guarantees that the raw reports were parsed,
#       # and that a 'vulnerabilities' key was found for each.
#       # (Each raw report's 'vulnerabilities' is an array of vulnerability hashes.)
#       # The .analyze method assumes that @results is an array of per-directory 'vulnerabilities' arrays.
#       # Each should be an array of vulnerability hashes with certain keys ('name', 'version', 'title', etc).

#       before { allow(Glue).to receive(:warn) } # stub to prevent printing to screen

#       context "in the root dir" do
#         let(:target) { 'malformed' }

#         before do
#           allow(task).to receive(:runsystem).with(*cli_args(target)).and_return(malformed_response)
#           task.run
#         end

#         context "equal to a non-array" do
#           # Would throw NoMethodError (calling .uniq on non-array):
#           let(:malformed_response) { JSON.generate({ vulnerabilities: true }) }

#           it "handles (does not raise) the NoMethodError" do
#             expect { task.analyze }.not_to raise_error
#           end

#           it "issues a notification matching 'Problem running Snyk'" do
#             expect(Glue).to receive(:notify).with(/Problem running Snyk/)
#             task.analyze rescue nil
#           end

#           it "issues a warning matching 'Error'" do
#             expect(Glue).to receive(:warn).with(/Error/)
#             task.analyze rescue nil
#           end
#         end

#         context "with a 'nil' vulnerability" do
#           # Would throw NoMethodError (trying to access a member of nil):
#           let(:malformed_response) { JSON.generate({ vulnerabilities: [nil] }) }

#           it "doesn't raise an error" do
#             expect { task.analyze }.not_to raise_error
#           end
#         end

#         context "with a vulnerability equal to an empty hash" do
#           # Would throw TypeError (trying to access eg 'id' of an empty hash):
#           let(:malformed_response) { JSON.generate({ vulnerabilities: [{}] }) }

#           it "doesn't raise an error" do
#             expect { task.analyze }.not_to raise_error
#           end
#         end
#       end

#       context "in a sub-dir, sibling to well-formed findings" do
#         let(:target) { 'malformed_nested'}
#         let(:sub_1_good) { 'finding_1' }
#         let(:sub_2_bad) { 'malformed' }
#         let(:sub_3_good) { 'zz_finding_1' }

#         let(:raw_report_1) { get_raw_report(target, sub_1_good) }
#         let(:malformed_response) { JSON.generate({ vulnerabilities: true }) }
#         let(:raw_report_3) { get_raw_report(target, sub_3_good) }

#         before do
#           allow(task).to receive(:runsystem).with(*cli_args(target, sub_1_good)).and_return(raw_report_1)
#           allow(task).to receive(:runsystem).with(*cli_args(target, sub_2_bad)).and_return(malformed_response)
#           allow(task).to receive(:runsystem).with(*cli_args(target, sub_3_good)).and_return(raw_report_3)
#           task.run
#         end

#         it "only issues one warning" do
#           expect(Glue).to receive(:warn).with(/Error/).once
#           task.analyze rescue nil
#         end

#         it "results in 2 findings (doesn't exit early)" do
#           task.analyze rescue nil
#           expect(task.findings.size).to eq(2)
#         end
#       end
#     end
#  end
end
