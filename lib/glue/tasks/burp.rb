require 'glue/tasks/base_task'
require 'glue/util'
require 'rexml/document'
require 'rexml/streamlistener'
include REXML

# SAX Like Parser for Burp Suite Pro Report XML.
class Glue::BurpListener
  include StreamListener

  def initialize(task)
    @task = task
    @text = ''
    @cdata = ''
    @type = ''
    @serial_number = ''
    @issue_name = ''
    @url = ''
    @path = ''
    @location = ''
    @severity = ''
    @confidence = ''
    @issue_background = ''
    @remediation_background = ''
    @references = ''
  end

  def tag_start(name, attrs)
  end

  def tag_end(name)
    case name
    when 'name'
        # Only take the first name tag, or we may end up with a tag from a child node (e.g. <reference>)
        if @issue_name.blank? && @text =~ /\D/
            @issue_name = @text
        end
    when 'serialNumber'
        @serial_number = @text
    when 'type'
        @type = @text
    when 'host'
        @url = @text
    when 'path'
        @path = @text
    when 'location'
        @location = @cdata
    when 'severity'
        @severity = @text
    when 'confidence'
        @confidence = @text
    when 'issueBackground'
        @issue_background = @cdata
    when 'remediationBackground'
        @remediation_background = @cdata
    when 'references'
        @references = @text
    when 'issue'
        background = @issue_background.gsub(/<\/?[^>]*>/, "").gsub("\n", '').strip
        remediation = @remediation_background.gsub(/<\/?[^>]*>/, "").gsub("\n", '').strip
        refs = @references.gsub(/<\/?[^>]*>/, "").gsub("\n", '').strip

        #report description, detail, source, severity, fingerprint
        @task.report @issue_name, "#{background}\n\n#{remediation}\n\n#{refs}", @location, @severity, @serial_number
    end
  end

  def text(text)
    @text = text
  end

  def cdata(cdata)
    @cdata = cdata
  end
end

class Glue::Burp < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Burp"
    @description = "Burp Suite Pro Issues"

    @stage = :code
    @labels << "code"

    @burp_xml_path = @tracker.options[:burp_xml_path]
  end

  def run
    Glue.notify "#{@name}"
  end

  def analyze
    begin
      Glue.debug "Parsing report #{@burp_xml_path}"
      get_warnings(@burp_xml_path)
    rescue Exception => e
      Glue.notify "Problem running Burp ... skipped."
      Glue.notify e.message
      raise e
    end
  end

  def supported?
    true
  end

  def get_warnings(path)
    listener = Glue::BurpListener.new(self)

    xml_stream = get_input_stream
    parser = Parsers::StreamParser.new(xml_stream, listener)
    parser.parse
  end

  def get_input_stream
    File.new(@tracker.options[:burp_xml_path])
  end
end
