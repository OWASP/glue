class Pipeline::Finding
  attr_reader :timestamp
  attr_reader :severity
  attr_reader :source
  attr_reader :description
  attr_reader :detail

  def initialize description, detail, source, severity
  	@timestamp = Time.now
  	@description = description
  	@detail = detail
  	@source = source
  	@severity = severity
  end

  def to_string
  	s = "Finding: #{@description}\t#{@timestamp}\t#{@source}\t#{@severity}\n"
  	s << "\t#{@detail}\n"
  	s
  end

end
