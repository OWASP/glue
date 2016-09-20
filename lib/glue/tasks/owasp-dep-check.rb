require 'glue/tasks/base_task'
require 'glue/util'
require 'rexml/document'
require 'rexml/streamlistener'
include REXML

# SAX Like Parser for OWASP DEP CHECK XML.
class Glue::DepCheckListener
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
      # Glue.debug "Grabbed #{@count} vulns."
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
      puts "Fingerprint: #{@fingerprint}"
      puts "Vuln: #{@name} CVSS: #{@cvss} Description #{description} Detail #{detail}"
      @task.report @name, description, detail, @cvss, @fingerprint
    end
  end

  def text(text)
    @text = text
  end
end

class Glue::OWASPDependencyCheck < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger,tracker)
    super(trigger,tracker)
    @name = "OWASP Dependency Check"
    @description = "Dependency analysis for Java and .NET"
    @stage = :code
    @labels << "code" << "java" << ".net"
  end

  def run
    Glue.notify "#{@name}"
    rootpath = @trigger.path
    @result= runsystem(true, "/home/glue/tools/dependency-check/bin/dependency-check.sh", "-a", "Glue", "-f", "XML", "-out", "#{rootpath}", "-s", "#{rootpath}")
  end

  def analyze
    path = @trigger.path + "/dependency-check-report.xml"
    begin
      Glue.debug "Parsing report #{path}"
      get_warnings(path)
    rescue Exception => e
      Glue.notify "Problem running OWASP Dep Check ... skipped."
      Glue.notify e.message
      raise e
    end
  end

  def supported?
    supported=runsystem(true, "/home/glue/tools/dependency-check/bin/dependency-check.sh", "-v")
    if supported =~ /command not found/
      Glue.notify "Install dependency-check."
      return false
    else
      return true
    end
  end

  def get_warnings(path)
    listener = Glue::DepCheckListener.new(self)
    parser = Parsers::StreamParser.new(File.new(path), listener)
    parser.parse
  end
end
