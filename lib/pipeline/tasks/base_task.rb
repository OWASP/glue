require 'pipeline/finding'
require 'set'
require 'digest'

class Pipeline::BaseTask
  attr_reader :findings, :warnings, :trigger, :labels
  attr_accessor :name
  attr_accessor :description
  attr_accessor :stage
  attr_accessor :appname

  def initialize(trigger)
    @findings = []
    @warnings = []
    @labels = Set.new
    @trigger = trigger
    @severity_filter = {
      :low => ['low','weak'],
      :medium => ['medium','med','average'],
      :high => ['high','severe','critical']
    }
  end

  def report description, detail, source, severity, fingerprint
    finding = Pipeline::Finding.new( @trigger.appname, description, detail, source, severity, fingerprint )
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


  def run
  end

  def analyze
  end

  def supported?
  end

  def severity sev
    sev = '' if sev.nil?
    return 'low' if @severity_filter[:low].include?(sev.strip.chomp.downcase)
    return 'medium' if @severity_filter[:medium].include?(sev.strip.chomp.downcase)
    return 'high' if @severity_filter[:high].include?(sev.strip.chomp.downcase)
    return 'unknown'
  end

end
