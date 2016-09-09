require 'glue/mounters/base_mounter'
require 'fileutils'

class Glue::GitMounter < Glue::BaseMounter

  Glue::Mounters.add self

  def initialize trigger, options
    super(trigger)
    @options = options
    @name = "Git"
    @description = "Pull a repo."
  end

  def mount target
    base = @options[:working_dir]

    Glue.debug "Making base."
    FileUtils.mkdir_p base

    # Grap the path part of the git url.
    protocol, path, suffix = target.match(/\A(.*\/\/)(.*)(.git)\z/i).captures
    working_target = File.expand_path(base + "" + path + "/")

    Glue.notify "Cleaning directory: #{working_target}"
    if ! Dir.exists? working_target
      Glue.notify "#{working_target} is not a directory."
      FileUtils.mkdir_p working_target
    else
      Glue.debug "Removing : #{working_target}"
      FileUtils.rm_rf working_target
      FileUtils.mkdir_p working_target
    end
      # result = `rm -rf #{working_target}`
      # puts result
    Glue.debug "Cloning into: #{working_target}"
    result = `git clone -q #{target} #{working_target}`
    # puts result
    #end
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
