require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'

class Pipeline::BundleAudit < Pipeline::BaseTask
  
  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger)
    super(trigger)
    @name = "Bundle Audit"
    @description = "Dependency Checker analysis for Ruby"
    @stage = :code
    @labels << "code" << "ruby"
  end
  
  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    Dir.chdir("#{rootpath}") do 
      @result= runsystem(true, "bundle-audit", "check")
    end
  end

  def analyze
#    puts @result
    begin
      get_warnings
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.notify "Appears not to be a project with Gemfile.lock ... bundle-audit skipped."
    end
  end

  def supported?
    supported=runsystem(true, "bundle-audit", "update")
    if supported =~ /command not found/
      Pipeline.notify "Run: gem install bundler-audit"
      return false
    else
      return true
    end
  end

  private 
  def get_warnings
    detail, gem, source, severity, fingerprint = '','','','',''
    @result.each_line do | line |
      if /\S/ !~ line
        # Signal section is over.  Reset variables and report.
        if detail != ''
          report "Gem #{gem} has known security issues.", detail, source, severity, fingerprint  
        end
        detail, gem, source, severity, fingerprint = '','','','', ''
      end

      name, value = line.chomp.split(':')
      case name
      when 'Name'
        gem << value
      when 'Version'
        gem << value
      when 'Advisory'
        source << value
        fingerprint = value
      when 'Criticality'
        severity << value
      when 'URL'
        detail << value
      when 'Title'
        detail << value
      when 'Solution'
        detail << value
      when 'Insecure Source URI found'
        report "Insecure GEM Source", "#{line} - use git or https", "BundlerAudit", "High", "bundlerauditgemsource"
      else
        if line =~ /\S/ and line !~ /Unpatched versions found/
          Pipeline.notify "Not sure how to handle line: #{line}"
        end
      end
    end
  end
  

end

