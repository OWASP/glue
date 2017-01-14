require 'glue/tasks/base_task'
require 'glue/util'
require 'find'
require 'pry'

class Glue::Npm < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "NPM"
    @description = "Node Package Manager"
    @stage = :file
    @labels << "file" << "javascript"
    @results = []
  end

  def run
    exclude_dirs = ['node_modules','bower_components']
    exclude_dirs = exclude_dirs.concat(@tracker.options[:exclude_dirs]).uniq if @tracker.options[:exclude_dirs]
    directories_with?('package.json', exclude_dirs).each do |dir|
      Glue.notify "#{@name} scanning: #{dir}"
      if @tracker.options.has_key?(:npm_registry)
        registry = "--registry #{@tracker.options[:npm_registry]}"
      else
        registry = nil
      end
      @command = "npm install -q --ignore-scripts #{registry}"
      @results << runsystem(true, @command, :chdir => dir)
    end
  end

  def analyze
    begin
      if @results.include? false
        Glue.warn 'Error installing javascript dependencies with #{@command}'
      end
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
    end
  end

  def supported?
    supported = find_executable0('npm')
    unless supported
      Glue.notify "Install npm: https://nodejs.org/en/download/"
      return false
    else
      return true
    end
  end

end
