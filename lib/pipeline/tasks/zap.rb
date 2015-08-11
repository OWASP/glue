require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'

require 'rexml/document'
require 'rexml/streamlistener'
include REXML

# SAX Like Parser for OWASP ZAP XML.
class Pipeline::ZAPListener
  include StreamListener
  
  def initialize(task)
    @task = task
    @count = 0
    @pluginid = ""
    @alert = ""
    @confidence = ""
    @riskdesc = ""
    @desc = ""
    @url = ""
    @param = ""
    @attack = ""
    @otherinfo = ""
    @solution = ""
    @reference = ""
    @wascid = ""
    @cwe = ""
    @fingerprint = ""
  end
  
  def tag_start(name, attrs)
    case name
    when "alertitem"
      @count = @count + 1 
      # Pipeline.debug "Grabbed #{@count} vulns."
      @pluginid = ""
      @alert = ""
      @confidence = ""
      @riskdesc = ""
      @desc = ""
      @url = ""
      @param = ""
      @attack = ""
      @otherinfo = ""
      @solution = ""
      @reference = ""
      @wascid = ""
      @cwe = ""
      @fingerprint = ""
    end
  end
  
  def tag_end(name)
    case name
    when "pluginid"
      @pluginid = @text
    when "alert"
      @alert = @text
    when "confidence"
      @confidence = @text
    when "riskdesc"
      @riskdesc = @text
    when "desc"
      @desc = @text
    when "uri"
      @url = @text
    when "param"
      @param = @text.strip
    when "attack"
      @attack = @text.strip 
    when "otherinfo"
      @otherinfo = @text.chomp
    when "solution"
      @solution = @text
    when "reference"
      @reference = @text
    when "wascid"
      @wascid = @text
    when "cwe"
      @cwe = @text
    when "alertitem"
      detail = get_detail
      description = get_description
      source = get_source
      get_fingerprint
      risk = "Risk: #{@riskdesc} / Confidence (of 1-3 Low, Medium, High): #{@confidence}"

      # puts "Vuln: #{@alert} Severity: #{risk}\n\tDescription: #{description}\n\tDetail: #{detail}"     
      # puts "\tFingerprint: #{@fingerprint}"
      @task.report description, detail, source, risk, @fingerprint
    end
  end

  def get_fingerprint 
    @fingerprint = "ZAP-#{@pluginid}-#{@url}-#{@alert}"
    if @param != ""
      @fingerprint << "-#{@param}"
    end
    if @cwe != ""
      @fingerprint << "-#{@cwe}"
    end
    if @wascid != ""
      @fingerprint << "-#{@wascid}"
    end
    @fingerprint = @fingerprint.strip.gsub("\n", "")
  end

  def get_source
      source = "ZAP Plugin: #{@pluginid} URL: #{@url}"
      source
  end


  def get_detail
      detail = "URL: #{@url}\n\t"
      if @param != ""
        detail << "Param: #{@param}\t"
      end
      if @attack != ""
        detail << "Attack: #{@attack}\n\t"
      end
      if @otherinfo != "" and @otherinfo.strip != ""
        detail << "Background: #{@otherinfo}\n\t"
      end
      if @reference != "" 
        detail << "Reference: #{@reference}\n\t"
      end
      if @solution != ""
        detail << "Solution: #{@solution}"
      end 
      detail
  end

  def get_description
      # Format description.
      description = ""
      if @cwe != ""
        description = "CWE: #{@cwe}\t"
      end
      if @wascid != ""
        description << "WASC ID: #{@wascid}\t"
      end
      description << "\n\tDesc: #{@desc}"
      description
  end

  def text(text)
    @text = text.chomp
  end
end

class Pipeline::Zap < Pipeline::BaseTask
  
  Pipeline::Tasks.add self
  include Pipeline::Util
  
  def initialize(trigger)
    super(trigger)
    @name = "ZAP"
    @description = "App Scanning"
    @stage = :live
    @labels << "live"
  end
  
  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path

    Pipeline.debug "Running ZAP on: #{rootpath}"
    @result = runsystem(true, "rm", "/tmp/zap.xml")
    Pipeline.debug "Remove old ZAP file."

    # ZAP CLI can be a little dicey on a Mac.  Rework to use an API!
    @result=runsystem(true, "java", "-Xmx512m","-jar","/area52/ZAP_2.4.1/zap-2.4.1.jar","-installdir", "/area52/ZAP_2.4.1","-quickurl","#{rootpath}","-quickout","/tmp/zap.xml","-cmd")
  end

  def analyze
    puts @result
    begin
      #path = @trigger.path + "/tmp/zap.xml"
      path = "/tmp/zap.xml"
      get_warnings(path)
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.notify "Problem running ZAP."
    end
  end

  def supported?
    supported=runsystem(true, "java","-Xmx512m","-jar", "/area52/ZAP_2.4.1/zap-2.4.1.jar", "-version")
    if supported =~ /2.4.1/ 
      return true
    else
      Pipeline.notify "Install ZAP from owasp.org"
      return false
    end
  end

  def get_warnings(path)
    listener = Pipeline::ZAPListener.new(self)
    parser = Parsers::StreamParser.new(File.new(path), listener)
    parser.parse
  end

end

