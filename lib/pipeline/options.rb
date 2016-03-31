require 'optparse'
require 'set'

#Parses command line arguments for Brakeman
module Pipeline::Options

  class << self

    #Parse argument array
    def parse args
      get_options args
    end

    #Parse arguments and remove them from the array as they are matched
    def parse! args
      get_options args, true
    end

    #Return hash of options and the parser
    def get_options args, destructive = false
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: pipeline [options] image/root/path"

        opts.separator ""
        opts.separator "Pipeline is a swiss army knife of security analysis tools."
        opts.separator "It has built in support for static analysis, AV, fim, and "
        opts.separator "is being extended to be used for analyzing all kinds of "
        opts.separator "projects, images or file systems."
        opts.separator ""
        opts.separator "Pipeline also features filters to perform deduplication "
        opts.separator "and the abilty to handle false positives."
        opts.separator ""
        opts.separator "See also the docker image."
        opts.separator ""

        opts.separator "Control options:"

        opts.on "-n", "--no-threads", "Run checks sequentially" do
          options[:parallel_checks] = false
        end

        opts.on "--[no-]progress", "Show progress reports" do |progress|
          options[:report_progress] = progress
        end

        opts.on "-T", "--target PATH", "Specify target" do |target|
          options[:target] = path
        end

        opts.on "-q", "--[no-]quiet", "Suppress informational messages" do |quiet|
          options[:quiet] = quiet
        end

        opts.on( "-z", "--exit-on-warn", "Exit code is non-zero if warnings found") do
          options[:exit_on_warn] = true
        end

        opts.separator ""
        opts.separator "Scanning options:"

        opts.on "-A", "--run-all-checks", "Run all default and optional checks" do
          options[:run_all_checks] = true
        end

        opts.on "-t", "--test Check1,Check2,etc", Array, "Only run the specified checks" do |checks|
          options[:run_tasks] ||= Set.new
          options[:run_tasks].merge checks
        end

        opts.on "-x", "--except Check1,Check2,etc", Array, "Skip the specified checks" do |skip|
          skip.each do |s|

            options[:skip_checks] ||= Set.new
            options[:skip_checks] << s
          end
        end

        opts.on "-a", "--appname NAME", "Override the inferred application name." do |appname|
          options[:appname] = appname
        end

        opts.on "-r", "--revision REV", "Specify a revision of software to pass on to checkmarx" do |revision|
          options[:revision] = revision
        end

        opts.on "-l", "--labels Label1,Label2,etc", Array, "Run the checks with the supplied labels" do |labels|
          options[:labels] ||= Set.new
          options[:labels].merge labels
        end

        opts.on "--add-checks-path path1,path2,etc", Array, "A directory containing additional out-of-tree checks to run" do |paths|
          options[:additional_checks_path] ||= Set.new
          options[:additional_checks_path].merge paths.map {|p| File.expand_path p}
        end

        opts.on "--npm-registry URL", "Use a custom npm registry when installing dependencies for javascript scanners" do |url|
          options[:npm_registry] = url
        end

        opts.on "--exclude path1,path2,path3,etc", Array, "A list of paths to ignore when running recursive tasks (npm, retirejs, snyk, etc)" do |paths|
          paths.each do |path|
            options[:exclude_dirs] ||= Set.new
            options[:exclude_dirs] << path
          end
        end

        opts.separator ""
        opts.separator "Output options:"

        opts.on "-d", "--debug", "Lots of output" do
          options[:debug] = true
        end

        opts.on "-f",
                "--format TYPE",
                [:text, :html, :csv, :tabs, :json, :jira, :markdown],
                "Specify output formats. Default is text" do |type|
          options[:output_format] = type
        end

        opts.on "--css-file CSSFile", "Specify CSS to use for HTML output" do |file|
          options[:html_style] = File.expand_path file
        end

        opts.on "-i IGNOREFILE", "--ignore-config IGNOREFILE", "Use configuration to ignore warnings" do |file|
          options[:ignore_file] = file
        end

        opts.on "-I", "--interactive-ignore", "Interactively ignore warnings" do
          options[:interactive_ignore] = true
        end

        opts.on "-o", "--output FILE", "Specify file for output. Defaults to stdout." do |file|
          options[:output_file] = file
        end

        opts.on "--summary", "Only output summary of warnings" do
          options[:summary_only] = true
        end

        opts.separator ""
        opts.separator "JIRA options:"

        opts.on "--jira-project PROJECT", "Specify the jira project to create issues in. If issue looks like APPS-13, this should be APPS." do |project|
          options[:jira_project] = project
        end

        opts.on "--jira-api-url URL", "Specify the jira rest api endpoint. Eg. domain.com/jira/jira/rest/api/2/." do |url|
          options[:jira_api_url] = url
        end

        opts.on "--jira-cookie COOKIE", "Specify the session cookie to get to Jira." do |cookie|
          options[:jira_cookie] = cookie
        end

        opts.on "--jira-component COMPONENT", "Specify the JIRA component to use." do |component|
          options[:jira_component] = component
        end

        opts.separator ""
        opts.separator "ZAP options:"

        opts.on "--zap-api-token token", "Specify the ZAP API token to use when connecting to the API" do |token|
          options[:zap_api_token] = token
        end

        opts.on "--zap-host HOST", "Specify the host ZAP is running on." do |host|
          options[:zap_host] = host
        end

        opts.on "--zap-port PORT", "Specify the port ZAP is running on." do |port|
          options[:zap_port] = port
        end

        opts.separator ""
        opts.separator "Checkmarx options:"

        opts.on "--checkmarx-user USER", "Specify the Checkmarx user to use when connecting to the API" do |user|
          options[:checkmarx_user] = user
        end

        opts.on "--checkmarx-password PASSWORD", "Specify password for the Checkmarx API user" do |password|
          options[:checkmarx_password] = password
        end

        opts.on "--checkmarx-server server", "Specify the API server to use for Checkmarx scans" do |server|
          options[:checkmarx_server] = server
        end

        opts.on "--checkmarx-log logfile", "Specify the log file to use for Checkmarx scans" do |logfile|
          options[:checkmarx_log] = logfile
        end

        opts.on "--checkmarx-project project", "Specify the full path of the Checkmarx project for this scan" do |project|
          options[:checkmarx_project] = project
        end

        opts.separator ""
        opts.separator "PMD options:"

        opts.on "--pmd-path PATH", "The full path to the base PMD directory" do |dir|
          options[:pmd_path] = dir
        end

        opts.on "--pmd-checks CHECK1,CHECK2", "The list of checks passed to PMD run.sh -R, default: 'java-basic,java-sunsecure'" do |checks|
          options[:pmd_checks] = checks
        end

        opts.separator ""
        opts.separator "FindSecurityBugs options:"

        opts.on "--findsecbugs-path PATH", "The full path to the base FindSecurityBugs directory" do |dir|
          options[:findsecbugs_path] = dir
        end

        opts.separator ""
        opts.separator "Configuration files:"

        opts.on "-c", "--config-file FILE", "Use specified configuration file" do |file|
          options[:config_file] = File.expand_path(file)
        end

        opts.on "-C", "--create-config [FILE]", "Output configuration file based on options" do |file|
          if file
            options[:create_config] = file
          else
            options[:create_config] = true
          end
        end

        opts.separator ""

        opts.on "-k", "--checks", "List all available vulnerability checks" do
          options[:list_checks] = true
        end

        opts.on "--optional-checks", "List optional checks" do
          options[:list_optional_checks] = true
        end

        opts.on "-v", "--version", "Show Pipeline version" do
          options[:show_version] = true
        end

        opts.on_tail "-h", "--help", "Display this message" do
          options[:show_help] = true
        end
      end

      if destructive
        parser.parse! args
      else
        parser.parse args
      end

      if options[:previous_results_json] and options[:output_files]
        options[:comparison_output_file] = options[:output_files].shift
      end

      return options, parser
    end
  end
end
