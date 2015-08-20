require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'
require 'digest'

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
    detail, jem, source, sev, hash = '','','','',''
    @result.each_line do | line |
      if /\S/ !~ line
        # Signal section is over.  Reset variables and report.
        if detail != ''
          report "Gem #{jem} has known security issues.", detail, source, sev, fingerprint(hash)
        end
        detail, jem, source, sev, hash = '','','','',''
      end

      name, value = line.chomp.split(':')
      case name
      when 'Name'
        jem << value
        hash << value
      when 'Version'
        jem << value
        hash << value
      when 'Advisory'
        source << value
        hash << value
      when 'Criticality'
        sev = severity(value.strip)
        hash << sev
      when 'URL'
        detail += line.chomp.split('URL:').last
      when 'Title'
        detail += ",#{value}"
      when 'Solution'
        detail += ": #{value}"
      when 'Insecure Source URI found'
        report "Insecure GEM Source", "#{line.chomp} - use git or https", "BundlerAudit", "high", fingerprint("bundlerauditgemsource#{line.chomp}")
      else
        if line =~ /\S/ and line !~ /Unpatched versions found/
          Pipeline.notify "Not sure how to handle line: #{line}"
        end
      end
    end
  end


end

