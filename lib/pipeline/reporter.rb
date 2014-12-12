class Pipeline::Reporter

  #Pass in path to the root of the Rails application
  def initialize 
  end

  def report tracker
#    if tracker.options[:output_files]
#    elsif tracker.options[:print_report]

    tracker.findings.each do |finding|
      puts finding.to_string
    end
  end

end
