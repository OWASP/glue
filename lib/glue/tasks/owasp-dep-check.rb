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
      if @name.empty? && @text =~ /\D/
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
      @jar_name.gsub!(/\:\s+/, '/') unless @jar_name.empty?
      detail = "#{@jar_name}\n#{urls}"
      description = @desc + "\n" + @cwe
      #@fingerprint = sw_str + "-" + @name
      @fingerprint = "#{@name}:#{@jar_name}"

      summary = "#{@name} in #{@jar_name}"

      # Convert CVSS score to 1-3 scale
      divisor = 10.0 / 3    # 10.0 is the CVSS max score
      @cvss = (@cvss.to_f / divisor).ceil

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
    @gradle_project = @tracker.options[:gradle_project]
    @maven_project = @tracker.options[:maven_project]
  end

  def run
    Glue.notify "#{@name}"
    rootpath = @trigger.path

    if @scala_project
      run_args = [ @sbt_path, "dependencyCheck" ]
    elsif @gradle_project
      run_args = [ "./gradlew", "dependencyCheckAnalyze" ]
    elsif @maven_project
      run_args = [ "mvn", "org.owasp:dependency-check-maven:check" ]
    else  
      run_args = [ @dep_check_path, "--project", "Glue", "-f", "ALL" ]
    end

    if @tracker.options[:owasp_dep_check_log]
      run_args << [ "-l", "#{rootpath}/depcheck.log" ]
    end

    if @tracker.options[:owasp_dep_check_suppression]
      run_args << [ "--suppression", "#{@tracker.options[:owasp_dep_check_suppression]}" ]
    end

    run_args << [ "-out", "#{rootpath}", "-s", "#{rootpath}" ] unless @scala_project || @gradle_project || @maven_project

    initial_dir = Dir.pwd
    Dir.chdir @trigger.path if @scala_project || @gradle_project || @maven_project
    @result= runsystem(true, *run_args.flatten)
    @sbt_settings = runsystem(true, @sbt_path, "dependencyCheckListSettings") if @scala_project
    Dir.chdir initial_dir if @scala_project || @gradle_project || @maven_project
  end

  def analyze
    path = if @scala_project
      #md = @result.match(/\e\[0m\[\e\[0minfo\e\[0m\] \e\[0mWriting reports to (?<report_path>.*)\e\[0m/)
      #md[:report_path] + "/dependency-check-report.xml"
      report_directory = @sbt_settings.match(/.*dependencyCheckOutputDirectory: (?<report_path>.*)\e\[0m/)
      report_directory[:report_path] + "/dependency-check-report.xml"
    elsif @gradle_project
      @trigger.path + "/build/reports/dependency-check-report.xml"
    elsif @maven_project
      @trigger.path + "/target/dependency-check-report.xml"
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
