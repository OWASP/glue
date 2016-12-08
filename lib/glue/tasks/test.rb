require 'glue/tasks/base_task'
require 'glue/util'

class Glue::Test < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Test"
    @description = "Test"
    @stage = :code
    @labels << "code" << "ruby"
  end

  def run
    # Glue.notify "#{@name}"
    rootpath = @trigger.path
    Glue.debug "Rootpath: #{rootpath}"
    @result= runsystem(true, "grep", "-R", "secret", :chdir => rootpath)
  end

  def analyze
    begin
      list = @result.split(/\n/)
      list.each do |match|
          report "Match", match, @name, :low, "fingerprint"
      end
  rescue Exception => e
      Glue.warn e.message
      Glue.notify "Error grepping ... "
    end
  end

  def supported?
    supported=runsystem(true, "grep", "-h")
    if supported =~ /usage/
      Glue.notify "Install grep."
      return false
    else
      return true
    end
  end

end
