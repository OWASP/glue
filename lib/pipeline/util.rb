require 'open3'
require 'pathname'
require 'digest'
require 'pry'

module Pipeline::Util

  def runsystem(report, *splat)
    Open3.popen3(*splat) do |stdin, stdout, stderr, wait_thr|

      Thread.new do
        if $logfile and report
          while line = stderr.gets do
            $logfile.puts line
          end
        end
      end

      return stdout.read.chomp
    end
  end

  def fingerprint text
    Digest::SHA2.new(256).update(text).to_s
  end

  def strip_archive_path path, delimeter
    path.split(delimeter).last.split('/')[1..-1].join('/')
  end

  def relative_path path, pwd
    pathname = Pathname.new(path)
    return path if pathname.relative?
    pathname.relative_path_from(Pathname.new pwd)
  end
end
