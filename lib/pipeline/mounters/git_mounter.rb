require 'pipeline/mounters/base_mounter'

class Pipeline::GitMounter < Pipeline::BaseMounter
  
  Pipeline::Mounters.add self
  
  def initialize trigger, options
    super(trigger)
    @options = options
    @name = "Git"
    @description = "Pull a repo."
  end

  def mount target
    base = @options[:working_dir]
    # Grap the path part of the git url.
    protocol, path, suffix = target.match(/\A(.*\/\/)(.*)(.git)\z/i).captures
    working_target = base + "/" + path + "/"
    Pipeline.notify "Cleaning directory: #{working_target}"
    if ! working_target.match(/\A.*\/line\/tmp\/.*/)
      Pipeline.notify "Bailing in case #{working_target} is malicious."      
    else
      result = `rm -rf #{working_target}`
      # puts result
      result = `git clone -q #{target} #{working_target}`
      # puts result
    end
    return working_target
  end

  def supports? target
    last = target.slice(-4,target.length)
    if last === ".git"
      return true
    else
      return false
    end
  end

end
