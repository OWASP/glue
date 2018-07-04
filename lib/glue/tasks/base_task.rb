require 'glue/finding'
require 'set'
require 'digest'

class Glue::BaseTask
  attr_reader :findings, :warnings, :trigger, :labels
  attr_accessor :name
  attr_accessor :description
  attr_accessor :stage
  attr_accessor :appname
  attr_accessor :result
  
  def initialize(trigger, tracker)
    @findings = []
    @warnings = []
    @labels = Set.new
    @trigger = trigger
    @tracker = tracker
    @severity_filter = {
      :low => ['low','weak', 'informational', 'info'],
      :medium => ['medium','med','average'],
      :high => ['high','severe','critical']
    }
  end

  def report description, detail, source, severity, fingerprint
    finding = Glue::Finding.new( @trigger.appname, description, detail, source, severity, fingerprint, self.class.name )
    @findings << finding
  end

  def warn warning
    @warnings << warning
  end

  def name
    @name
  end

  def description
    @description
  end

  def stage
    @stage
  end

  def directories_with? file, exclude_dirs = []
    exclude_dirs = @tracker.options[:exclude_dirs] if exclude_dirs == [] and @tracker.options[:exclude_dirs]
    results = []

    Find.find(@trigger.path) do |path|
      if FileTest.directory? path
        Find.prune if exclude_dirs.include? File.basename(path) or exclude_dirs.include? File.basename(path) + '/'
        next
      end

      Find.prune unless File.basename(path) == file

      results << File.dirname(path)
    end
    return results
  end

  def run
  end

  def analyze
  end

  def supported?
  end

  def severity sev
    sev = '' if sev.nil?
    return 1 if @severity_filter[:low].include?(sev.strip.chomp.downcase)
    return 2 if @severity_filter[:medium].include?(sev.strip.chomp.downcase)
    return 3 if @severity_filter[:high].include?(sev.strip.chomp.downcase)
    puts "unsupperted severity found: " + sev
    return 0
  end

end
