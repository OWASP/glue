# https://github.com/jessek/hashdeep/releases/tag/release-4.4

require 'pipeline/tasks/base_task'
require 'open3'

class Pipeline::FIM < Pipeline::BaseTask
  Pipeline::Tasks.add self

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = 'FIM'
    @description = 'File integrity monitor'
    @stage = :file
    @result = ''
    @labels << 'filesystem'
  end

  def run
    Pipeline.notify @name.to_s
    rootpath = @trigger.path
    if File.exist?("/area81/tmp/#{rootpath}/filehash")
      Pipeline.notify 'File Hashes found, comparing to file system'
      cmd = "hashdeep -j99 -r -a -vv -k /area81/tmp/#{rootpath}/filehash #{rootpath}"

      # Ugly stdout parsing
      r = /(.*): No match/
      Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
        while line = stdout.gets
          @result << line if line.match r
        end
      end
    else
      Pipeline.notify 'No existing baseline - generating initial hashes'
      cmd = "mkdir -p /area81/tmp/#{rootpath}; hashdeep -j99 -r #{rootpath} > /area81/tmp/#{rootpath}/filehash"
      Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
        while line = stdout.gets
          puts '.'
          end
      end
      @result = ''
    end
  end

  def analyze
    list = @result.split(/\n/)
    list.each do |v|
      # v.slice! installdir
      Pipeline.notify v
      report 'File changed.', v, @name, :low
    end
  end

  def supported?
    # In future, verify tool is available.
    true
  end
end
