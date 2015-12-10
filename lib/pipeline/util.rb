require 'open3'
require 'pathname'
require 'digest'

module Pipeline::Util

  def runsystem(report,*splat)
    Open3.popen3(*splat) do |stdin, stdout, stderr, wait_thr|
      #puts *splat
      pid   = wait_thr.pid
      res = stdout.read
      error = stderr.read
      exit  = wait_thr.value

      if wait_thr.value != 0 && report
        # Weird. wait_thr value is non-0 for bundler-audit
        # but not brakeman. Comment to keep output cleaner...
        # puts res
        puts error
        #puts *splat
      end
      return res
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
