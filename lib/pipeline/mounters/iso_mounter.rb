require 'pipeline/mounters/base_mounter'

class Pipeline::ISOMounter < Pipeline::BaseMounter
  
  # THIS DOESN'T WORK SO DON'T REGISTER FOR NOW
  # Pipeline::Mounters.add self
  
  def initialize trigger, options
    super(trigger)
    @options = options
    @name = "ISO"
    @description = "Mount an iso image."
  end

  def mount target
    base = @options[:working_dir]
    working_target = base + "/" + target + "/"    
    Pipeline.notify "Cleaning directory: #{working_target}"

    Pipeline.notify "This doesn't work on MAC for some reason."
    # TODO:  COME BACK AND TEST ON LINUX AND FIX FOR MAC

    if ! working_target.match(/\A\/var\/redsky\/.*/)
      Pipeline.notify "Bailing in case #{working_target} is malicious."      
    else
      result = `rm -rf #{working_target}`
      # puts result
      result = `mkdir -p #{working_target}`
      # puts result
      Pipeline.notify "Mounting #{target} to #{working_target}"
      result = `mount -t iso9660 #{target} #{working_target}`
      # puts result
    end
    return working_target
  end

  def supports? target
    last = target.slice(-4,target.length)
    if last === ".iso"
      return true
    else
      return false
    end
  end
end
