require 'glue/tasks/base_task'
require 'glue/util'

class Glue::NodeSecurityProject < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "NodeSecurityProject"
    @description = "Node Security Project"
    @stage = :code
    @labels << "code" << "javascript" << "node"
    @results = []
  end

  def run
    exclude_dirs = ['node_modules','bower_components']
    exclude_dirs = exclude_dirs.concat(@tracker.options[:exclude_dirs]).uniq if @tracker.options[:exclude_dirs]
    directories_with?('package.json', exclude_dirs).each do |dir|
      Glue.notify "#{@name} scanning: #{dir}"
      res = runsystem(true, "nsp", "check", "--output", "json", :chdir => dir)
      @results << JSON.parse(res)
    end
  end

  def analyze
    begin
      @results.each do |dir_result|
        # This block iterates through each package name found and selects the unique nsp advisories
        # regardless of version, and builds a Glue finding hash for each unique package/advisory combo.
        dir_result.uniq {|finding| finding['module']}.each do |package|
          dir_result.select {|f| f['module'] == package['module']}.uniq {|m| m['advisory']}.each do |unique_finding|
            description = "#{unique_finding['module']} - #{unique_finding['title']}"
            detail = "Upgrade to versions: #{unique_finding['patched_versions']}\n#{unique_finding['advisory']}"
            source = {
              :scanner => 'NodeSecurityProject',
              :file => "#{unique_finding['module']} - #{unique_finding['vulnerable_versions']}",
              :line => nil,
              :code => nil
            }
            report description, detail, source, 'medium', fingerprint("#{description}#{detail}#{source}")
          end
        end
      end
    rescue Exception => e
      Glue.warn e.message
      Glue.warn e.backtrace
    end
  end

  def supported?
    supported=runsystem(true, "nsp", "--version")
    if supported =~ /command not found/
      Glue.notify "Install nodesecurity: 'npm install -g nsp'"
      return false
    else
      return true
    end
  end

end
