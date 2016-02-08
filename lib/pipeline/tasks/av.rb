# https://gist.github.com/paulspringett/8802240

require 'pipeline/tasks/base_task'

class Pipeline::AV < Pipeline::BaseTask

  Pipeline::Tasks.add self

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = 'AV'
    @description = 'Test for virus/malware'
    @stage = :file
    @labels << 'filesystem'
  end

  def run
    # Update AV
    `freshclam`
    # Run AV
    # TODO:  Circle back and use runsystem.
    Pipeline.notify 'Malware/Virus Check'
    rootpath = @trigger.path
    @result = `clamscan --no-summary -i -r "#{rootpath}"`
  end

  def analyze
    list = @result.split(/\n/)
    list.each do |v|
      # v.slice! installdir
      Pipeline.notify v
      report 'Malicious file identified.', v, @name, :medium
    end
  end

  def supported?
    # TODO: verify.
    # In future, verify tool is available.
    true
  end
end
