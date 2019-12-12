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
      should have(8).items
    end

    it "should fill all the required fields" do
      finding = subject[0]
      expect(finding.severity).to eq(3)
      expect(finding.description).to eq("Debugging was enabled on the app which makes it easier for reverse engineers to hook a debugger to it. This allows dumping a stack trace and accessing debugging helper classes.")
      expect(finding.detail).to eq("Debug Enabled For App<br>[android:debuggable=true]")
      expect(finding.source).to eq("Debug Enabled For App<br>[android:debuggable=true]")
      expect(finding.fingerprint).to eq("Debug Enabled For App<br>[android:debuggable=true]")
      expect(finding.appname).to eq("InsecureBankv2")
      expect(finding.task).to eq("MobSF")
    end
  end

   # The tests used the report after transformed with JQ, see the documentation for more details
   context "zaproxy" do
    let(:task) { get_dynamic_task_buildin_mapping "tools_samples/zaproxy.json", "zaproxy"}
    subject(:task_findings) { task.findings }
    before do 
      task.run
    end
    it "should produce one finding" do
      should have(1).items
    end

    it "should fill all the required fields" do
      finding = subject[0]
      expect(finding.severity).to eq(1)
      expect(finding.description).to eq("<p>Base64 encoded data was disclosed by the application/web server</p>")
      expect(finding.detail).to eq("Base64 Disclosure \n Evidence: DxyPP_YQ6qdWluCCz93Xs1CeJPvg \n Solution: <p>Manually confirm that the Base64 data does not leak sensitive information, and that the data cannot be aggregated/used to exploit other vulnerabilities.</p> \n Other info: <p>\\x000f\\x001c�?�\\x0010�V���Re\\x000c��9�7C\\x001b \\x0011Ű�\\x0004?a\tP�\\x0017���\u007f@]ۺ�\\x0005\\x0007��7\\x0006\\x000e���\\x0019�,�D[�n���_)��X�w��&^���3l����'�~h?��O\\x0011�H����΅\\x001c��ޕ�Bi|��>\\x0007\u007f:�-QY(\\x0016</p><p>��A|��9��E��%&\\x0011�]�j\\x001c!��o�\\x000e�\\x0014԰�L�\\x0000j:\\x0008V:��]L����փԫ�o$\\x0003����KՆn��5�T_P�ͭ�w����l$\\x000fU���+vq\\x001e\\x001b& P\n7+���u9�\\x001e��tN����+\\x0003�X�R$\\,��{5\t�O</p> \n Reference: <p>https://www.owasp.org/index.php/Top_10_2013-A6-Sensitive_Data_Exposure</p><p>http://projects.webappsec.org/w/page/13246936/Information%20Leakage</p>")
      expect(finding.source).to eq("URI: http://api:9999/ Method: POST")
      expect(finding.fingerprint).to eq("10094_http://api:9999/_POST")
      expect(finding.appname).to eq("http://api:9999")
      expect(finding.task).to eq("OWASP Zaproxy")
    end
  end

  context "snyk" do
    let(:task) { get_dynamic_task_buildin_mapping "tools_samples/snyk.json", "snyk"}
    subject(:task_findings) { task.findings }
    before do 
      task.run
    end
    it "should produce one finding" do
      should have(2).items
    end

    it "should fill all the required fields" do
      finding = subject[0]
      expect(finding.severity).to eq(2)
      expect(finding.description).to eq("Denial of Service (DoS)")
      expect(finding.detail).to eq("description")
      expect(finding.source).to eq("Microsoft.AspNetCore.All")
      expect(finding.fingerprint).to eq("SNYK-DOTNET-MICROSOFTASPNETCOREALL-60258")
      expect(finding.appname).to eq("dummy/obj")
      expect(finding.task).to eq("Snyk")
    end
  end
 end
