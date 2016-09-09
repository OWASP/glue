require 'glue/tasks/base_task'
require 'json'
require 'glue/util'
require 'find'

class Glue::SFL < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger,tracker)
    @name = "SFL"
    @description = "Sentive Files Lookup"
    @stage = :code
    @labels << "code"
    # Glue.debug "initialized SFL"
    @patterns = read_patterns_file!
  end

  def run
    # Glue.notify "#{@name}"
    @files = Find.find(@trigger.path)
    Glue.debug "Found #{@files.count} files"
  end

  def analyze
    begin
      @files.each do |file|
        @patterns.each do |pattern|
          case pattern['part']
            when 'filename'
              if pattern_matched?(File.basename(file), pattern)
                report pattern['caption'], pattern['description'], @name + ":" + file, 'unknown', 'TBD'
              end
            when 'extension'
              if pattern_matched?(File.extname(file), pattern)
                report pattern['caption'], pattern['description'], @name + ":" + file, 'unknown', 'TBD'
              end
          end
        end
      end
    rescue Exception => e
      Glue.warn e.message
    end
  end

  def supported?
    true
  end

  def pattern_matched?(txt, pattrn)
    case pattrn['type']
      when 'match'
        return txt == pattrn['pattern']
      when 'regex'
        regex = Regexp.new(pattrn['pattern'], Regexp::IGNORECASE)
        return !regex.match(txt).nil?
    end
  end

  def read_patterns_file!
    JSON.parse(File.read("#{File.dirname(__FILE__)}/patterns.json"))
  rescue JSON::ParserError => e
    Glue.warn "Cannot parse pattern file: #{e.message}"
  end
end
