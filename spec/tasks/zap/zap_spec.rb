require 'spec_helper'
require 'addressable/template'
require 'glue'
require 'glue/event'
require 'glue/tracker'
require 'glue/tasks'
require 'glue/tasks/zap'


describe Glue::Zap do
  # Run 'spec/tasks/snyk/generate_reports.sh' to generate the reports
  # for any new 'targets' you want to test against.
  ZAP_TARGET_URL = "http://app"

  def get_zap(target = '')
    trigger = Glue::Event.new(target)
    trigger.path = File.join(ZAP_TARGET_URL, target)
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
        stub_request(:get, "http://zap:1234/JSON/core/view/version/?apikey=key")
            .to_return(body: "{\"version\":\"2.9.0\"}", status: 200,
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
        stub_request(:any, "http://zap:1234/JSON/core/view/version/?apikey=key").
            to_return(body: "{\"version\":\"2.6.0\"}", status: 200,
            headers: { 'Content-Length' => 19 })
        allow(Glue).to receive(:notify) # stub Glue.notify to prevent printing to screen
      end

      it { is_expected.to be_supported }
    end

  end

   describe "#analyze" do
    subject(:task) { get_zap }

    before do
      set_zap_params!(subject, "http://zap", 1234, "key")
      allow(Glue).to receive(:notify) # stub Glue.notify to prevent printing to screen
    end

    context "when using pasive mode" do
      before do
        enable_passive_mode(subject)
        stub_request(:get, "http://zap:1234/JSON/pscan/view/recordsToScan/")
          .with(query: {"apikey" => "key", "formMethod" => "GET", "zapapiformat" => "JSON"})
          .to_return(body: "{\"recordsToScan\":\"0\"}", status: 200,
          headers: { 'Content-Length' => 21})

        stub_request(:get, "http://zap:1234/JSON/core/view/alerts/?apikey=key&baseurl=http://app/")
          .to_return(body: File.read('spec/tasks/zap/alerts.json').chomp, status: 200)

        task.run
        task.analyze
      end

      it "should return all relevant alerts from Zap" do
        expect(task.findings.size).to eq(2)
      end

      it "should extract all fields from Zap" do
        finding = task.findings[0]
        expect(finding.description).to eq("description")
        expect(finding.source).to eq("ZAPhttp://juiceshop/")
        expect(finding.severity).to eq(2)
        expect(finding.fingerprint).to eq("ZAPhttp://juiceshop/Storable but Non-Cacheable Contentparam")
        expect(finding.detail).to eq("""Url: http://juiceshop/ Param: param
Reference: https://tools.ietf.org/html/rfc7234
https://tools.ietf.org/html/rfc7231
http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html (obsoleted by rfc7234)
Solution: solution
CWE: 524\tWASCID: 13""")
      end
    end
   end
end
