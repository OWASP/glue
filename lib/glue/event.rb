# Tracks internal glue events.
# Can be used for control, but also tracking what happens.
class Glue::Event
  attr_reader :parent
  attr_accessor :path
  attr_accessor :appname

  def initialize appname, parent = nil
  	@appname = appname
   	@parent = parent
   	@timestamp = Time.now
  end

end
