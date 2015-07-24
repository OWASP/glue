require 'pipeline/filters/base_filter'

class Pipeline::RemoveAllFilter < Pipeline::BaseFilter
  
  #Pipeline::Filters.add self
  
  def initialize
    @name = "Remove All Filter"
    @description = "Remove all the things..."
  end

  def filter tracker
    tracker.findings.clear
  end

end
