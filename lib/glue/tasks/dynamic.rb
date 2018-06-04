require 'glue/tasks/base_task'
require 'glue/util'
require 'json'
require 'json-schema'

class Glue::Dynamic < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util
  
  MAPPING_NAME_REGEX = /\A\w{0,20}\z/
  MAPPING_FOLDER = File.join(File.dirname(__FILE__), "../mappings")
  SCHEMA_FILE_PATH = File.join(MAPPING_FOLDER, "schema.json")

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Dynamic Task"
    @description = "Dynamic task that parse JSON reports by using a mappings file"
    @stage = :code
    @labels << "code"
  end

  def run
    mapping_schema = JSON.parse(File.read(SCHEMA_FILE_PATH))
    report_path = "#{@tracker.options[:target]}"
    mapping_file_path = "#{@tracker.options[:mapping_file_path]}"

    if (!!MAPPING_NAME_REGEX.match(mapping_file_path) && 
          File.exist?(File.join(MAPPING_FOLDER, "#{mapping_file_path}.json"))) 
      mapping_file_path = File.join(MAPPING_FOLDER, "#{mapping_file_path}.json")
    elsif (!File.exist?(mapping_file_path))
      Glue.fatal "Mapping file #{mapping_file_path} not found"
    end

    if (!File.exist?(report_path))
      Glue.fatal "Report #{report_path} not found"
    end

    report = JSON.parse(File.read(report_path))
    mappings = JSON.parse(File.read(mapping_file_path))

    errors = JSON::Validator.fully_validate(mapping_schema, mappings, :validate_schema => true)

    if errors.any? 
      Glue.fatal "Invalid mappings JSON: #{errors.inspect}"
    end

    app_name = report[mappings["app_name"]]
    task_name = mappings["task_name"]

    mappings["mappings"].each do |map| 
      key = map["key"]

      if (report[key] == nil)
        Glue.fatal "report does not contains key '#{key}''"
      end

      report[key].each do |item| 
        description = item[map["properties"]["description"]]
        detail = item[map["properties"]["detail"]]
        source = item[map["properties"]["source"]]
        severity_raw = item[map["properties"]["severity"]]
        fingerprint = item[map["properties"]["fingerprint"]]
        finding = Glue::Finding.new( app_name, description, detail, source, severity(severity_raw), fingerprint, task_name )
        @findings << finding
      end
    end

  end

  def analyze
  end

  def supported?
    return true
  end

end
