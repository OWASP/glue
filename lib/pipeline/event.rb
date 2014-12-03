# Tracks internal pipeline events.
# Can be used for control, but also tracking what happens.
class Pipeline::Event
  attr_reader :parent
  attr_accessor :path

  def initialize parent = nil
   	@parent = parent
   	@timestamp = Time.now
  end

end
