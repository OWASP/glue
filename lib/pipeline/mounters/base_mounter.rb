
class Pipeline::BaseMounter
  attr_reader :errors
  attr_reader :trigger
  attr_accessor :name
  attr_accessor :description

  def initialize(trigger)
    @errors = []
    @trigger = trigger
  end

  def error(error)
    @errors << error
  end

  attr_reader :name

  attr_reader :description

  def mount
  end

  def supports?(target)
  end
end
