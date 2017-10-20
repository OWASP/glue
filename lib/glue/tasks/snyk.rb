require 'glue/tasks/base_task'
require 'glue/util'
require 'redcarpet'

class Glue::Snyk < Glue::BaseTask

  Glue::Tasks.add self
  include Glue::Util

  BASE_EXCLUDE_DIRS = %w(node_modules bower_components).freeze

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Snyk"
    @description = "Snyk.io JS dependency checker"
    @stage = :code
    @labels << "code" << "javascript"
    @results = []
  end

  def run
    directories_with?('package.json', exclude_dirs).each do |dir|
      Glue.notify "#{@name} scanning: #{dir}"
      raw_output = runsystem(true, "snyk", "test", "--json", :chdir => dir)
      parsed_output = parse_snyk(raw_output)
      @results << parsed_output unless parsed_output.nil?
    end

    self
  end

  def analyze
    @results.each do |dir_results|
      # We build a single finding for each uniq result ID within a given directory,
      # adding the unique info (upgrade path and files) as a list.
      begin
        dir_results.chunk { |r| r['id'] }.each do |_, results|
          result = results.first

          description = "#{result['name']}@#{result['version']} - #{result['title']}"
          detail = markdown_to_html(result['description'])
          source = build_source_hash(results)
          sev = severity(result['severity'])
          fprint = fingerprint("#{description}#{detail}#{source}#{sev}")

          report description, detail, source, sev, fprint
        end
      rescue NoMethodError, TypeError => e
        log_error(e)
      end
    end

    self
  end

  def supported?
    supported = find_executable0('snyk')

    unless supported
      Glue.notify "Install Snyk: 'npm install -g snyk'"
      false
    else
      true
    end
  end

  private

  def exclude_dirs
    extra_exclude_dirs = @tracker.options[:exclude_dirs] || []
    BASE_EXCLUDE_DIRS | extra_exclude_dirs
  end

  def parse_snyk(raw_output)
    JSON.parse(raw_output)["vulnerabilities"]
  rescue JSON::ParserError, TypeError => e
    log_error(e)
    nil
  end

  def log_error(e)
    Glue.notify "Problem running Snyk"
    Glue.warn e.inspect
    Glue.warn e.backtrace
  end

  def markdown_to_html(markdown)
    # Use Redcarpet to render the Markdown details to something pretty for web display
    @@markdown_engine ||= Redcarpet::Markdown.new Redcarpet::Render::HTML.new(link_attributes: {target: "_blank"}), autolink: true, tables: true
    @@markdown_engine.render(markdown).gsub('h2>','strong>').gsub('h3>', 'strong>')
  end

  def build_source_hash(results)
    # Consolidate the list of files and upgrade paths for all results with the same 'id'
    # in the same directory.
    # This uses the same form as the retirejs task so it all looks nice together.

    upgrade_paths = [ "Upgrade Path:\n" ]
    files = []

    results.each do |res|
      res['upgradePath'].each_with_index do |upgrade, i|
        upgrade_paths << "#{res['from'][i]} -> #{upgrade}"
      end
      files << res['from'].join('->')
    end

    {
      :scanner => @name,
      :file => files.join('<br>'),
      :line => nil,
      :code => upgrade_paths.uniq.join("\n"),
    }
  end
end
