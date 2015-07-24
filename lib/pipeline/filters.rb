class Pipeline::Filters
  @filters = []

  #Add a task. This will call +_klass_.new+ when running tests
  def self.add klass
    @filters << klass unless @filters.include? klass
  end

  def self.filters
    @filters
  end

  def self.initialize_filters filters_directory = ""
    Dir.glob(File.join(filters_directory, "*.rb")).sort.each do |f|
      require f
    end
  end

  #No need to use this directly.
  def initialize options = { }
  end

  #Run all the tasks on the given Tracker.
  #Returns a new instance of tasks with the results.
  def self.filter(tracker)
    @filters.each do |c|
      filter = c.new() 
      begin
        filter.filter(tracker)
      rescue => e
        Pipeline.error e.message
        tracker.error e
      end
    end
  end
end

#Load all files in filters/ directory
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/filters/*.rb").sort.each do |f|
  require f.match(/(pipeline\/filters\/.*)\.rb$/)[0]
end
