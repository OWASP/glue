class Pipeline::BaseFilter
  attr_accessor :name
  attr_accessor :description

  def initialize
  end

  attr_reader :name

  attr_reader :description

  def filter
  end
end
