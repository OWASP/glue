class Pipeline::Reporter

  #Pass in path to the root of the Rails application
  def initialize options
    @options = options
  end

  def report tracker
#    if options[:output_files]
#    elsif options[:print_report]

    tracker.findings.each do |finding|
      puts finding.to_string
    end
  end

end
