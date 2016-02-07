require 'pipeline/mounters/base_mounter'

class Pipeline::FileSystemMounter < Pipeline::BaseMounter
  Pipeline::Mounters.add self

  def initialize(trigger, options)
    super(trigger)
    @options = options
    @name = 'FileSystem'
    @description = 'Mount a file via normal file system commands.'
  end

  def mount(target)
    target
  end

  def supports?(target)
    last = target.slice(-1)
    if last === '/' || last === '.'
      return true
    else
      return false
    end
  end
end
