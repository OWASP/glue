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
    working_target = File.expand_path(base + "" + path + "/")
    Pipeline.notify "Cleaning directory: #{working_target}"
    if ! File.directory? working_target or ! File.exists? working_target
      Pipeline.notify "#{working_target} is not a directory."      
    else
      Pipeline.debug "Removing : #{working_target}"
      result = `rm -rf #{working_target}`
      # puts result
      Pipeline.debug "Cloning into: #{working_target}"
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
