require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'
require 'jsonpath'
require 'pathname'

class Pipeline::RetireJS < Pipeline::BaseTask

  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "RetireJS"
    @description = "Dependency analysis for JavaScript"
    @stage = :code
    @labels << "code" << "javascript"
  end

  def run
    rootpath = @trigger.path
    Pipeline.debug "Retire rootpath: #{rootpath}"
    Dir.chdir("#{rootpath}") do
      if @tracker.options.has_key?(:npm_registry)
        registry = "--registry #{@tracker.options[:npm_registry]}"
      else
        registry = nil
      end
      @result = `npm install --ignore-scripts #{registry}`  # Need this even though it is slow to get full dependency analysis.
    end
    @result = `retire -c --outputformat json --path #{rootpath} 2>&1`
  end

  def analyze
    begin
      vulnerabilities = parse_retire_json(JSON.parse(@result))

      vulnerabilities.each do |vuln|
        report "Package #{vuln[:package]} has known security issues", vuln[:detail], vuln[:source], vuln[:severity], fingerprint("#{vuln[:package]}#{vuln[:source]}#{vuln[:severity]}")
      end
    rescue Exception => e
      Pipeline.warn e.message
      Pipeline.warn e.backtrace
    end
  end

  def parse_retire_json result
    Pipeline.debug "Retire JSON Raw Result:  #{result}"
    vulnerabilities = []
    # This is very ugly, but so is the json retire.js spits out
    # Loop through each component/version combo and pull all results for it
    JsonPath.on(result, '$..component').uniq.each do |comp|
      JsonPath.on(result, "$..results[?(@.component == \'#{comp}\')].version").uniq.each do |version|
        vuln_hash = {}
        vuln_hash[:package] = "#{comp}-#{version}"

        version_results = JsonPath.on(result, "$..results[?(@.component == \'#{comp}\')]").select { |r| r['version'] == version }.uniq

        # If we see the parent-->component relationship, dig through the dependency tree to try and make a dep map
        deps = []
        obj = version_results[0]
        while !obj['parent'].nil?
          deps << obj['parent']['component']
          obj = obj['parent']
        end
        if deps.length > 0
          vuln_hash[:source] = { :scanner => @name, :file => "#{deps.reverse.join('->')}->#{comp}-#{version}", :line => nil, :code => nil }
        end

        vuln_hash[:severity] = 'unknown'
        # pull detail/severity
        version_results.each do |version_result|
          JsonPath.on(version_result, '$..vulnerabilities').uniq.each do |vuln|
            vuln_hash[:severity] = severity(vuln[0]['severity'])
            vuln_hash[:detail] = vuln[0]['info'].join('\n')
          end
        end

        vulnerabilities << vuln_hash
      end
    end

    # Loop through the separately reported 'file' findings so we can tag the source (no dep map here)
    result.select { |r| !r['file'].nil? }.each do |file_result|
      JsonPath.on(file_result, '$..component').uniq.each do |comp|
        JsonPath.on(file_result, "$..results[?(@.component == \'#{comp}\')].version").uniq.each do |version|
          source_path = Pathname.new(file_result['file']).relative_path_from Pathname.new(@trigger.path)
          vulnerabilities.select { |v| v[:package] == "#{comp}-#{version}" }.first[:source] = { :scanner => @name, :file => source_path.to_s, :line => nil, :code => nil }
        end
      end
    end
    return vulnerabilities
  end

  def supported?
    supported=runsystem(true, "retire", "--help")
    if supported =~ /command not found/
      Pipeline.notify "Install RetireJS"
      return false
    else
      return true
    end
  end

end

