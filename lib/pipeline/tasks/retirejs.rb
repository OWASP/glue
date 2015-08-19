require 'pipeline/tasks/base_task'
require 'json'
require 'pipeline/util'
require 'digest'
require 'jsonpath'

class Pipeline::RetireJS < Pipeline::BaseTask

  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger)
    super(trigger)
    @name = "RetireJS"
    @description = "Dependency analysis for JavaScript"
    @stage = :code
    @labels << "code" << "javascript"
  end

  def run
    Pipeline.notify "#{@name}"
    rootpath = @trigger.path
    # runsystem() doesn't work with redirected stderr
    #@result=runsystem(true, "retire", "-c", "--outputformat", "json", "--path", "#{rootpath}", "2>&1")
    @result = `retire -c --outputformat json --path #{rootpath} 2>&1`
  end

  def analyze
    # puts @result
    begin
      result = JSON.parse(@result)
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
            vuln_hash[:source] = deps.reverse.join('->')
            vuln_hash[:source] << "->#{comp}-#{version}"
          end

          # pull detail/severity
          version_results.each do |version_result|
            JsonPath.on(version_result, '$..vulnerabilities').uniq.each do |vuln|
              case vuln[0]['severity']
              when 'low'
                vuln_hash[:severity] = 'low'
              when 'medium'
                vuln_hash[:severity] = 'medium'
              when 'high'
                vuln_hash[:severity] = 'high'
              else
                vuln_hash[:severity] = 'unknown'
              end
              vuln_hash[:detail] = vuln[0]['info'].join(',')
            end
          end

          vulnerabilities << vuln_hash
        end
      end

      # Loop through the separately reported 'file' findings so we can tag the source (no dep map here)
      result.select { |r| !r['file'].nil? }.each do |file_result|
        JsonPath.on(file_result, '$..component').uniq.each do |comp|
          JsonPath.on(file_result, "$..results[?(@.component == \'#{comp}\')].version").uniq.each do |version|
            # this is horrible, if someone can figure out a better way to do this please fix:
            if file_result['file'].include?('github_explorer_extracted_archive/')
              source_path = file_result['file'].split('github_explorer_extracted_archive/').last.split('/')[1..-1].join('/')
            else
              source_path = file_result['file']
            end
            vulnerabilities.select { |v| v[:package] == "#{comp}-#{version}" }.first[:source] = source_path
          end
        end
      end

      # generate fingerprints for our findings and report them up
      vulnerabilities.each do |vuln|
        vuln[:fingerprint] = Digest::SHA2.new(256).update("#{vuln[:package]}#{vuln[:source]}#{vuln[:severity]}").to_s
        report "Package #{vuln[:package]} has known security issues", vuln[:detail], vuln[:source], vuln[:severity], vuln[:fingerprint]
      end
    rescue Exception => e
      Pipeline.warn e.message
    end
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

