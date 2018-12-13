require 'glue/tasks/base_task'
require 'glue/util'
require 'json'
require 'jsonpath'

class Glue::RetireJS < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  SUPPORTED_CHECK_STR = 'retire --help'.freeze
  BASE_EXCLUDE_DIRS = %w[node_modules bower_components].freeze

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = 'RetireJS'
    @description = 'Dependency analysis for JavaScript'
    @stage = :code
    @labels << 'code' << 'javascript'
    @results = []
  end

  def run
    directories_with?('package.json', exclude_dirs).each do |dir|
      Glue.notify "#{@name} scanning: #{dir}"
      command_line = 'retire -c --outputpath /dev/stdout ' \
        "--outputformat json --path #{dir}"
      raw_output = runsystem(true, command_line)
      @results << raw_output
    end

    self
  end

  def analyze
    # Each element of @results is a string (the output of 'retire')
    # representing all results for a given package.json directory.

    @results.each do |raw_results|
      begin
        vulnerabilities = parse_retire_results(raw_results)
        report_findings!(vulnerabilities)
      rescue StandardError => e
        log_error(e)
      end
    end

    self
  end

  def supported?
    runsystem(false, supported_check_str)
    true
  rescue Errno::ENOENT # gets raised if the command isn't found
    Glue.notify "Install RetireJS: 'npm install -g retire'"
    false
  end

  private

  def exclude_dirs
    extra_exclude_dirs = @tracker.options[:exclude_dirs] || []
    BASE_EXCLUDE_DIRS | extra_exclude_dirs
  end

  def supported_check_str
    # The main purpose of this method is to allow stubbing
    # the 'supported_check_str' in the spec tests, without modifying
    # the SUPPORTED_CHECK_STR itself.
    SUPPORTED_CHECK_STR
  end

  def report_findings!(vulnerabilities)
    vulnerabilities.each do |vuln|
      description = "#{vuln[:package]} has known security issues"
      detail = vuln[:detail]
      source = vuln[:source]
      sev = vuln[:severity]
      fprint = fingerprint("#{vuln[:package]}#{source}#{sev}#{detail}")

      report description, detail, source, sev, fprint
    end
  end

  def parse_retire_results(raw_results)
    all_results = JSON.parse(raw_results)
    Glue.debug "Retire JSON Raw Results:  #{all_results}"

    return [] if all_results.nil?

    js_results, npm_results = all_results.partition do |result|
      result.key?('file')
    end

    js_vulnerabilities(js_results) + npm_vulnerabilities(npm_results)
  end

  def js_vulnerabilities(results)
    parse_vulnerabilities(results, false)
  end

  def npm_vulnerabilities(results)
    parse_vulnerabilities(results, true)
  end

  def parse_vulnerabilities(results, for_npm)
    findings = []
    names_versions = get_name_version_combos(results)

    names_versions.each do |name, version|
      filtered = filter_results(results, name, version)
      proto_result = filtered.first

      source_tag = if for_npm
                     npm_dependency_maps(filtered)
                   else
                     js_vuln_filenames(results, name, version)
                   end

      curr_findings = vulnerability_hashes(proto_result, source_tag)
      findings.concat(curr_findings)
    end

    findings
  end

  def get_name_version_combos(results)
    name_version_combos = []
    names = JsonPath.on(results, '$..component').uniq

    names.each do |name|
      versions_filter = "$..results[?(@.component == \'#{name}\')].version"
      versions = JsonPath.on(results, versions_filter).uniq
      curr_combos = versions.map { |version| [name, version] }
      name_version_combos.concat(curr_combos)
    end

    name_version_combos
  end

  def filter_results(results, name, version)
    name_filter = "$..results[?(@.component == \'#{name}\')]"
    by_name = JsonPath.on(results, name_filter)

    by_name_and_version = by_name.select do |result|
      result['version'] == version
    end.uniq

    by_name_and_version
  end

  def npm_dependency_maps(package_results)
    maps = []

    package_results.each do |package|
      deps = []
      nested_comp = package

      while nested_comp['parent']
        deps << nested_comp['parent']['component']
        nested_comp = nested_comp['parent']
      end

      next if deps.empty?

      package_info = package_tag(package_results.first)
      map = "#{deps.reverse.join('->')}->#{package_info}"
      maps << map
    end

    maps.join("\n")
  end

  def js_vuln_filenames(js_results, name, version)
    # Each vuln file has its own js_result hash, with
    # possibly several diff't js lib vulns. Go through
    # each file's hash and check if it contains a vuln
    # related to the supplied name/version.

    js_results.each_with_object([]) do |js_result, filenames|
      not_relevant = filter_results(js_result, name, version).empty?
      next if not_relevant

      abs_file_path = js_result['file']
      abs_dir_path = File.expand_path(@trigger.path)
      filename = relative_path(abs_file_path, abs_dir_path).to_s
      filenames << filename
    end.join("\n")
  end

  def vulnerability_hashes(proto_result, source_tag)
    if !proto_result.has_key?('vulnerabilities')
      return []
    end
    proto_result['vulnerabilities'].each_with_object([]) do |vuln, vulns|
      vuln_hash = {
        package: package_tag(proto_result),
        source: { scanner: @name, file: source_tag, line: nil, code: nil },
        severity: severity(vuln['severity']),
        detail: vuln['info'].join("\n")
      }
      vulns << vuln_hash
    end
  end

  def package_tag(result)
    name = result['component']
    version = result['version']
    "#{name}-#{version}"
  end

  def log_error(e)
    Glue.notify 'Problem running RetireJS'
    Glue.warn e.inspect
    Glue.warn e.backtrace
  end
end
