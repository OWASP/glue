require 'glue/mounters/base_mounter'

class Glue::FileSystemMounter < Glue::BaseMounter
  Glue::Mounters.add self

  def initialize trigger, options
    super(trigger)
    @options = options
    @name = "FileSystem"
    @description = "Mount a file via normal file system commands."
  end

  def mount target
    return target
  end

  def supports? target
    File.directory? target
  end
end
