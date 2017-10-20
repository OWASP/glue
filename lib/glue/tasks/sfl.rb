require 'glue/tasks/base_task'
require 'glue/util'
require 'json'
require 'find'
require 'English'

class Glue::SFL < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  PATTERNS_FILE_PATH = File.join(File.dirname(__FILE__), "patterns.json")

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "SFL"
    @description = "Sensitive File Lookup (SFL)"
    @stage = :code
    @labels << "code"
    @results = []
    self
  end

  def run
    begin
      Glue.notify @name
      run_sfl!
    rescue StandardError => e
      log_error(e)
    end

    self
  end

  def analyze
    @results.each do |result|
      begin
        report_finding! result
      rescue StandardError => e
        log_error(e)
      end
    end

    self
  end

  def supported?
    true
  end

  def self.patterns
    @patterns ||= read_patterns_file
    @patterns.dup
  end

  def self.matches?(filepath, pattern)
    text = extract_filepart(filepath, pattern)
    pattern_matched?(text, pattern)
  end

  private

  def run_sfl!
    files = Find.find(@trigger.path).select { |path| File.file?(path) }
    Glue.debug "Found #{files.count} files"

    files.each do |filepath|
      self.class.patterns.each do |pattern|
        if self.class.matches?(filepath, pattern)
          @results << { filepath: filepath, pattern: pattern }
        end
      end
    end

    nil
  end

  def report_finding!(result)
    pattern = result[:pattern]
    filepath = result[:filepath]

    description = pattern['caption']
    detail = pattern['description']
    source = "#{@name}:#{filepath}"
    severity = 'unknown'
    fprint = fingerprint("SFL-#{pattern['part']}#{pattern['type']}" \
                          "#{pattern['pattern']}#{filepath}")

    report description, detail, source, severity, fprint
  end

  private_class_method def self.read_patterns_file
    JSON.parse(File.read(PATTERNS_FILE_PATH))
  rescue
    modified_message = "#{$ERROR_INFO} (problem with SFL patterns file)"
    raise $ERROR_INFO, modified_message, $ERROR_INFO.backtrace
  end

  private_class_method def self.extract_filepart(filepath, pattern)
    case pattern['part']
    when 'filename'   then File.basename(filepath)
    when 'extension'  then File.extname(filepath).gsub(/^\./, '')
    when 'path'       then filepath
    else ''
    end
  end

  private_class_method def self.pattern_matched?(text, pattern)
    case pattern['type']
    when 'match'
      text == pattern['pattern']
    when 'regex'
      regex = Regexp.new(pattern['pattern'], Regexp::IGNORECASE)
      !!regex.match(text)
    else
      false
    end
  end

  def log_error(e)
    Glue.notify "Problem running SFL"
    Glue.warn e.inspect
    Glue.warn e.backtrace
  end
end
