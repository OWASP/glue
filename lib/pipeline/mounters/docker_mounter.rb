require 'pipeline/mounters/base_mounter'

class Pipeline::DockerMounter < Pipeline::BaseMounter

  Pipeline::Mounters.add self
  
  #Pass in path to the root of the Rails application
  def initialize trigger, options
  	super(trigger)
    @options = options
  end

  def mount target
    return target
  end

  def applies? target
    last = target.slice(-1)
    if last === "ABLA"
      return true
    else
      return false
    end
  end
end
