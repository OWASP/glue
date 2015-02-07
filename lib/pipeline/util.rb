require 'open3'

module Pipeline::Util
  
  def runsystem(report,*splat)
    Open3.popen3(*splat) do |stdin, stdout, stderr, wait_thr|
      #puts *splat
      pid   = wait_thr.pid 
      res = stdout.read
      error = stderr.read
      exit  = wait_thr.value

      if wait_thr.value != 0 && report
        puts res
        puts error
        #puts *splat
      end
      return res
    end
  end
end
