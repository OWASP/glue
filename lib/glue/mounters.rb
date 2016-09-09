# Knows how to test file types and then defer to the helper.

require 'glue/event'

class Glue::Mounters
  @mounters = []

  attr_reader :target
  attr_reader :warnings

  def self.add klass
    @mounters << klass unless @mounters.include? klass
  end

  def self.mounters
  	@mounters
  end

  def initialize
  	@warnings = []
  end

  def add_warning warning
    @warnings << warning
  end

  def self.mount tracker
  	target = tracker.options[:target]
  	Glue.debug "Mounting target: #{target}"
  	trigger = Glue::Event.new(tracker.options[:appname])
  	@mounters.each do | c |
  	  mounter = c.new trigger, tracker.options
 	  begin
	  	Glue.debug "Checking about mounting #{target} with #{mounter}"
  	    if mounter.supports? target
	  	  Glue.notify "Mounting #{target} with #{mounter}"
	  	  path = mounter.mount target
	  	  Glue.notify "Mounted #{target} with #{mounter}"
		  return path
	  	end
	  rescue => e
	  	Glue.notify e.message
	  end
  	end
  end

   def self.get_mounter_name mounter_class
    mounter_class.to_s.split("::").last
  end
end

#Load all files in mounters/ directory
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/mounters/*.rb").sort.each do |f|
  require f.match(/(glue\/mounters\/.*)\.rb$/)[0]
end
