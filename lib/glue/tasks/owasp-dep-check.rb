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
    @sw = [ ]
    @url = [ ]
    @desc = ""
    @cwe = ""
    @cvss = ""
    @name = ""
    @fingerprint = ""
  end

  def tag_start(name, attrs)
    case name
    when 'dependency'
      @jar_name = ''
    when "vulnerability"
      @count = @count + 1
      # Glue.debug "Grabbed #{@count} vulns."
      @sw = [ ]
      @url = [ ]
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
      # Only take the first name tag, or we may end up with a tag from a child node (e.g. <reference>)
      if @name.blank? && @text =~ /\D/
        @name = @text
      end
    when "cvssScore"
      @cvss = @text
    when "cwe"
      @cwe = @text
    when "description"
      @desc = @text
    when "vulnerableSoftware"
    when "software"
      @sw << @text
    when "url"
      @url << ", " << @text
    when 'fileName'
      @jar_name = @text
    when "vulnerability"
      sw_str = @sw.join(', ')
      
      urls = @url.reject { |s| s =~ /\s*,\s*/ }.join(', ')

      #detail = sw_str + "\n" + @url
      @jar_name.gsub!(/\:\s+/, '/') unless @jar_name.blank?
      detail = "#{@jar_name}\n#{urls}"
      description = @desc + "\n" + @cwe
      #@fingerprint = sw_str + "-" + @name
      @fingerprint = "#{@name}:#{@jar_name}"

      summary = "#{@name} in #{@jar_name}"

      puts "Fingerprint: #{@fingerprint}"
      puts "Vuln: #{@name} CVSS: #{@cvss} Description #{description} Detail #{detail}"
      @task.report summary, description, detail, @cvss, @fingerprint

      @sw = ""
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

    @dep_check_path = @tracker.options[:owasp_dep_check_path]
    @sbt_path = @tracker.options[:sbt_path]
    @scala_project = @tracker.options[:scala_project]
  end

  def run
    Glue.notify "#{@name}"
    rootpath = @trigger.path

    if @scala_project
      run_args = [ @sbt_path, "dependencyCheck" ]
    else  
      run_args = [ @dep_check_path, "--project", "Glue", "-f", "ALL" ]
    end

    if @tracker.options[:owasp_dep_check_log]
      run_args << [ "-l", "#{rootpath}/depcheck.log" ]
    end

    if @tracker.options[:owasp_dep_check_suppression]
      run_args << [ "--suppression", "#{@tracker.options[:owasp_dep_check_suppression]}" ]
    end

    run_args << [ "-out", "#{rootpath}", "-s", "#{rootpath}" ] unless @scala_project

    puts "Running #{run_args.flatten}"
    @result= runsystem(true, *run_args.flatten)
    puts "Result: #{@result}"
  end

  def analyze
    path = if @scala_project
      md = @result.match(/\[info\] Writing reports to (?<report_path>.*)/)
      puts "matched against @result: #{@result}"
      puts "md: #{md}"
      md[:report_path] + "/dependency-check-report.xml"
    else
      @trigger.path + "/dependency-check-report.xml"
    end

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
    supported=runsystem(true, @dep_check_path, "-v")
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
