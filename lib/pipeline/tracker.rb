require 'json'

class Pipeline::Tracker
  attr_reader :options
  attr_reader :warnings
  attr_reader :errors
  attr_reader :findings

  # Pass in the options.
  # Let the Tracker be the one thing that gets passed around
  # with options and collecting output.
  def initialize options
    @options = options
    @warnings = []
    @errors = []
    @findings = []
  end

  #Process events that
  def process event

  end

  def error error
    @errors << error
  end

  def warn warning
    @warnings << warning
  end

  def report finding
    @findings << finding
  end  

  def to_json
    s = "{ \"findings\": [ "
    @findings.each do |finding|
      s << finding.to_json
      s << ","
    end
    s = s.slice(0,s.length-1) # One easy way to remove the last ,
    s << "] }"
    s

  end
end
