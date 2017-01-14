require 'glue/tasks/base_task'
require 'json'
require 'glue/util'
require 'digest'

class Glue::BundleAudit < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "BundleAudit"
    @description = "Dependency Checker analysis for Ruby"
    @stage = :code
    @labels << "code" << "ruby"
    @results = {}
  end

  def run
    directories_with?('Gemfile.lock').each do |dir|
      Glue.notify "#{@name} scanning: #{dir}"
      @results[dir] = runsystem(true, "bundle-audit", "check", :chdir => dir)
    end
  end

  def analyze
    # puts @result
    begin
      get_warnings
    rescue Exception => e
      Glue.warn e.message
      Glue.notify "Appears not to be a project with Gemfile.lock or there was another problem ... bundle-audit skipped."
    end
  end

  def supported?
    supported=runsystem(false, "bundle-audit", "update")
    if supported =~ /command not found/
      Glue.notify "Run: gem install bundler-audit"
      return false
    else
      return true
    end
  end

  private
  def get_warnings
    @results.each do |dir, result|
      detail, jem, source, sev, hash = '','',{},'',''
      result.each_line do | line |

        if /\S/ !~ line
          # Signal section is over.  Reset variables and report.
          if detail != ''
            report "Gem #{jem} has known security issues.", detail, source, sev, fingerprint(hash)
          end

          detail, jem, source, sev, hash = '','', {},'',''
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
          source = { :scanner => @name, :file => "#{relative_path(dir, @trigger.path)}/Gemfile.lock", :line => nil, :code => nil }
          hash << value
        when 'Criticality'
          sev = severity(value)
          hash << sev
        when 'URL'
          detail += line.chomp.split('URL:').last
        when 'Title'
          detail += ",#{value}"
        when 'Solution'
          detail += ": #{value}"
        when 'Insecure Source URI found'
          report "Insecure GEM Source", "#{line.chomp} - use git or https", {:scanner => @name, :file => 'Gemfile.lock', :line => nil, :code =>  nil}, severity('high'), fingerprint("bundlerauditgemsource#{line.chomp}")
        else
          if line =~ /\S/ and line !~ /Unpatched versions found/
            Glue.debug "Not sure how to handle line: #{line}"
          end
        end
      end
    end
  end


end
