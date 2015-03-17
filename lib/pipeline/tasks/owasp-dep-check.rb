require 'pipeline/tasks/base_task'
require 'pipeline/util'
require 'rexml/document'
require 'rexml/streamlistener'
include REXML

# SAX Like Parser for OWASP DEP CHECK XML.
class Pipeline::DepCheckListener
  include StreamListener
  
  def initialize(task)
    @task = task
    @count = 0
    @sw = ""
    @url = ""
    @desc = ""
    @cwe = ""
    @cvss = ""
    @name = ""
    @fingerprint = ""
  end
  
  def tag_start(name, attrs)
    case name
    when "vulnerability"
      @count = @count + 1 
      Pipeline.debug "Grabbed #{@count} vulns."
      @sw = ""
      @url = ""
      @desc = ""
      @cwe = ""
      @cvss = ""
      @name = ""
      @fingerprint = ""
    end
  end
  
  def tag_end(name)
    case name
    when "name"
      if @text =~ /\D/
        @name = @text
      end
    when "cvssScore"
      @cvss = @text
    when "cwe"
      @cwe = @text
    when "description"
      @desc = @text
    when "vulnerableSoftware"
      @sw = ""
    when "software"
      @sw << ", " << @text
    when "url"
      @url << ", " << @text
    when "vulnerability"
      detail = @sw + "\n"+ @url
      description = @desc + "\n" + @cwe
      @fingerprint = @sw+"-"+@name
      puts "Vuln: #{@name} CVSS: #{@cvss} Description #{description} Detail #{detail}"
      @task.report @name, description, detail, @cvss, @fingerprint
    end
  end
  
  def text(text)
    @text = text
  end
end

class Pipeline::OWASPDependencyCheck < Pipeline::BaseTask
  
  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger)
    super(trigger)
    @name = "OWASP Dependency Check"
    @description = "Dependency analysis for Java and .NET"
    @stage = :code
    @labels << "code" << "java" << ".net"
  end
  
  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    @result= runsystem(true, "/area52/dependency-check/bin/dependency-check.sh", "-a", "pipeline", "-f", "XML", "-out", "#{rootpath}", "-s", "#{rootpath}")
  end

  def analyze
    path = @trigger.path + "/dependency-check-report.xml"
    @result = File.open(path, "rb").read
#    puts @result
    begin
      Pipeline.debug "Parsing report #{path}"
      Pipeline.debug "#{@result}"
      get_warnings(path)
    rescue Exception => e
      Pipeline.notify "Problem running OWASP Dep Check ... skipped."
      Pipeline.notify e.message
      raise e
    end
  end

  def supported?
    supported=runsystem(true, "/area52/dependency-check/bin/dependency-check.sh", "-v")
    if supported =~ /command not found/
      Pipeline.notify "Install dependency-check."
      return false
    else
      return true
    end
  end

  def get_warnings(path)
    listener = Pipeline::DepCheckListener.new(self)
    parser = Parsers::StreamParser.new(File.new(path), listener)
    parser.parse
  end
end



