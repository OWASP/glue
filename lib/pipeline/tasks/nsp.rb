require 'pipeline/tasks/base_task'
require 'pipeline/util'

class Pipeline::NodeSecurityProject < Pipeline::BaseTask
  Pipeline::Tasks.add self
  include Pipeline::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = 'NodeSecurityProject'
    @description = 'Node Security Project'
    @stage = :code
    @labels << 'code'
  end

  def run
    Pipeline.notify @name.to_s
    rootpath = @trigger.path
    Dir.chdir(rootpath.to_s) do
      @results = JSON.parse `nsp check --output json 2>&1`
    end
  end

  def analyze
    # This block iterates through each package name found and selects the unique nsp advisories
    # regardless of version, and builds a pipeline finding hash for each unique package/advisory combo.
    @results.uniq { |finding| finding['module'] }.each do |package|
      @results.select { |f| f['module'] == package['module'] }.uniq { |m| m['advisory'] }.each do |unique_finding|
        description = "#{unique_finding['module']} - #{unique_finding['title']}"
        detail = "Upgrade to versions: #{unique_finding['patched_versions']}\n#{unique_finding['advisory']}"
        source = {
          scanner: 'NodeSecurityProject',
          file: "#{unique_finding['module']} - #{unique_finding['vulnerable_versions']}",
          line: nil,
          code: nil
        }
        report description, detail, source, 'medium', fingerprint("#{description}#{detail}#{source}")
      end
    end
  rescue Exception => e
    Pipeline.warn e.message
    Pipeline.warn e.backtrace
  end

  def supported?
    supported = runsystem(true, 'nsp', '--version')
    if supported =~ /command not found/
      Pipeline.notify "Install nodesecurity: 'npm install -g nsp'"
      return false
    else
      return true
    end
  end
end
