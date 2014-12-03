# Knows how to test file types and then defer to the helper.


class Pipeline::Mounter
  attr_reader :target

  def initialize target
   	@target = target
  end

  # Degenerate for now.  Just return the path.
  def mount
  	@target
  end

end