require 'glue/filters/base_filter'

class Glue::RemoveAllFilter < Glue::BaseFilter

  #Glue::Filters.add self

  def initialize
    @name = "Remove All Filter"
    @description = "Remove all the things..."
  end

  def filter tracker
    tracker.findings.clear
  end

end
