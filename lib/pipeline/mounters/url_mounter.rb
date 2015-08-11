require 'pipeline/mounters/base_mounter'

class Pipeline::URLMounter < Pipeline::BaseMounter
  Pipeline::Mounters.add self
  
  def initialize trigger, options
    super(trigger)
    @options = options
    @name = "URL"
    @description = "Mount a url."
  end

  def mount target
    return target
  end

  def supports? target
    start = target.slice(0,4)
    if start === "http"
      return true
    else
      return false
    end
  end
end
