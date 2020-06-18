require 'glue/mounters/base_mounter'
require 'fileutils'

class Glue::AzDOMounter < Glue::BaseMounter

  Glue::Mounters.add self

  def initialize trigger, options
    super(trigger)
    @options = options
    @name = "AzDO Git"
    @description = "Pull a repo."
  end

  def mount target
    base = @options[:working_dir]

    Glue.debug "Making base."
    FileUtils.mkdir_p base

    # Grab the path used as git url, excluding PAT.
    # format of this target must be https://DUMMY:<PAT_TOKEN>@dev.azure.com/<account>/<project>/_git/<repository>
    protocol, azdo_domain, account, project, repository = target.match(/\A(.*\/\/).*@(.*)\/(.*)\/(.*)\/_git\/(.+?)[\/]{0,1}\z/i).captures

    path = [azdo_domain, account, project, repository].map{|i| '/'+i}.join
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
    if target.include?("@dev.azure.com/") && target.include?("/_git/")
      return true
    else
      return false
    end
  end

end
