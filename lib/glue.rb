require 'rubygems'
require 'yaml'
require 'set'
require 'tempfile'

module Glue

  #This exit code is used when warnings are found and the --exit-on-warn
  #option is set
  Warnings_Found_Exit_Code = 3

  @debug = false
  @quiet = false
  @loaded_dependencies = []

  #Run Glue.
  #
  #Options:
  #
  #  * :config_file - configuration file
  #  * :exit_on_warn - return false if warnings found, true otherwise. Not recommended for library use (default: false)
  #  * :output_files - files for output
  #  * :output_formats - formats for output (:to_s, :to_tabs, :to_csv, :to_html)
  #  * :parallel_checks - run checks in parallel (default: true)
  #  * :print_report - if no output file specified, print to stdout (default: false)
  #  * :quiet - suppress most messages (default: true)
  def self.run options
    options = set_options options
    @quiet = !!options[:quiet]
    @debug = !!options[:debug]

    if @quiet
      options[:report_progress] = false
    end

    unless options[:logfile].nil?
      puts "Logfile nil?"

      if options[:logfile].is_a? File
        $logfile = options[:logfile]
      else
        $logfile = File.open(options[:logfile], 'a')
      end

      begin
        puts "calling scan"
        scan options
      ensure
        $logfile.close unless options[:logfile].is_a? File
      end
    end
  end

  #Sets up options for run, checks given application path
  def self.set_options options
    if options.is_a? String
      options = { :target => options }
    end

    if options[:quiet] == :command_line
      command_line = true
      options.delete :quiet
    end

    options = default_options.merge(load_options(options[:config_file], options[:quiet])).merge(options)

    if options[:quiet].nil? and not command_line
      options[:quiet] = true
    end

    options[:output_format] = get_output_format options

    if options[:appname].nil?
      path = options[:target]
      options[:appname] = File.split(path).last
    end
    options
  end

  CONFIG_FILES = [
    File.expand_path("./config/glue.yml"),
    File.expand_path("~/.glue/config.yml"),
    File.expand_path("/etc/glue/config.yml")
  ]

  #Load options from YAML file
  def self.load_options custom_location, quiet
    #Load configuration file
    if config = config_file(custom_location)
      options = YAML.load_file config

      if options
        options.each { |k, v| options[k] = Set.new v if v.is_a? Array }

        # notify if options[:quiet] and quiet is nil||false
        notify "[Notice] Using configuration in #{config}" unless (options[:quiet] || quiet)
        options
      else
        notify "[Notice] Empty configuration file: #{config}" unless quiet
        {}
      end
    else
      {}
    end
  end

  def self.config_file custom_location = nil
    supported_locations = [File.expand_path(custom_location || "")] + CONFIG_FILES
    supported_locations.detect {|f| File.file?(f) }
  end

  #Default set of options
  def self.default_options
    {
      :parallel_tasks => true,
      :logfile => "/tmp/glue.txt",
      :skip_tasks => Set.new(),
      :exit_on_warn => true,
      :output_format => [:text],
      :working_dir => "~/glue/tmp/",
      :jira_api_context => '',
      :pivotal_api_url => 'https://www.pivotaltracker.com/services/v5/projects/',
      :zap_host => "http://localhost",
      :zap_port => "9999",
      :owasp_dep_check_path => '/home/glue/tools/dependency-check/bin/dependency-check.sh',
      :sbt_path => '/usr/bin/sbt',
      :findsecbugs_path => '/home/glue/tools/findbugs-3.0.1',
      :labels => Set.new() << "filesystem" << "code"     # Defaults to run.
    }
  end

  #Determine output formats based on options[:output_formats]
  #or options[:output_files]
  def self.get_output_format options
    res = [ ]

    if options[:output_file]
      res << get_format_from_output_file(options[:output_file])
    end
    
    if options[:output_format]
      res << get_format_from_output_format(options[:output_format])
    end

    if res.empty?
      begin
        require 'terminal-table'
        res << :to_s
      rescue LoadError
        res << :to_json
      end
    end

    res.flatten
  end

  def self.get_format_from_output_format output_format
    case output_format
    when :csv, :to_csv
      [:to_csv]
    when :json, :to_json
      [:to_json]
    when :jira, :to_jira
      [:to_jira]
    when :pivotal, :to_pivotal
      [:to_pivotal]
    when :teamcity, :to_teamcity
      [:to_teamcity]
    when :slack
      [:to_slack]
    else
      [:to_s]
    end
  end
  private_class_method :get_format_from_output_format

  def self.get_format_from_output_file output_file
      case output_file
      when /\.csv$/i
        [:to_csv]
      when /\.json$/i
        [:to_json]
      else
        [:to_s]
      end
  end
  private_class_method :get_format_from_output_file

  #Output list of tasks (for `-k` option)
  def self.list_checks options
    require 'glue/scanner'

    add_external_tasks options

    if options[:list_optional_tasks]
      $stderr.puts "Optional Tasks:"
      tasks = Tasks.optional_tasks
    else
      $stderr.puts "Available tasks:"
      tasks = Tasks.tasks
    end

    format_length = 30

    $stderr.puts "-" * format_length
    tasks.each do |task|
      $stderr.printf("%-#{format_length}s\n", task.name)
    end
  end

  #Output configuration to YAML
  def self.dump_config options
    if options[:create_config].is_a? String
      file = options[:create_config]
    else
      file = nil
    end

    options.delete :create_config

    options.each do |k,v|
      if v.is_a? Set
        options[k] = v.to_a
      end
    end

    if file
      File.open file, "w" do |f|
        YAML.dump options, f
      end
      puts "Output configuration to #{file}"
    else
      puts YAML.dump(options)
    end
    exit
  end

  #Run a scan. Generally called from Glue.run instead of directly.
  def self.scan options
    #Load scanner
    puts "Running scanner"
    notify "Loading scanner..."

    begin
      require 'glue/scanner'
      require 'glue/tracker'
      require 'glue/mounters'
      require 'glue/filters'
      require 'glue/reporters'

    rescue LoadError => e
      $stderr.puts e.message
      raise NoGlueError, "Cannot find lib/ directory or load the key glue."
    end

#    debug "API: #{options[:jira_api_url.to_s]}"
#    debug "Project: #{options[:jira_project.to_s]}"
#    debug "Cookie: #{options[:jira_cookie.to_s]}"

    add_external_tasks options

    tracker = Tracker.new options
    debug "Mounting ... #{options[:target]}"
    # Make the target accessible.
    target = Glue::Mounters.mount tracker

    #Start scanning
    scanner = Scanner.new
    notify "Processing target...#{options[:target]}"
    scanner.process target, tracker

    # Filter the results (Don't report anything that has been reported before)
    Glue::Filters.filter tracker

    # Generate Report
    begin
      Glue::Reporters.run_report tracker
    rescue Exception => e
      puts "Error running report #{e.message}"
      error e
    end
    tracker
  end

  def self.fatal message
    $stderr.puts message
    $logfile.puts "[#{Time.now}] #{message}" if $logfile
    exit!(1)
  end

  def self.error message
    $stderr.puts message
    $logfile.puts "[#{Time.now}] #{message}" if $logfile
  end

  def self.warn message
    $stderr.puts message unless @quiet
    $logfile.puts "[#{Time.now}] #{message}" if $logfile
  end

  def self.notify message
    $stderr.puts message #unless @debug
    $logfile.puts "[#{Time.now}] #{message}" if $logfile
  end

  def self.debug message
    $stderr.puts message if @debug
    $logfile.puts "[#{Time.now}] #{message}" if $logfile
  end

  def self.load_glue_dependency name
    return if @loaded_dependencies.include? name

    begin
      require name
    rescue LoadError => e
      $stderr.puts e.message
      $stderr.puts "Please install the appropriate dependency."
      exit! -1
    end
  end

  def self.add_external_tasks options
    options[:additional_tasks_path].each do |path|
      Glue::Tasks.initialize_tasks path
    end if options[:additional_tasks_path]
  end

  class DependencyError < RuntimeError; end
  class NoGlueError < RuntimeError; end
  class NoTargetError < RuntimeError; end
  class JiraConfigError < RuntimeError; end
end
