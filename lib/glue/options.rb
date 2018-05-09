require 'optparse'
require 'set'

#Parses command line arguments for Brakeman
module Glue::Options

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
        opts.banner = "Usage: Glue [options] image/root/path"

        opts.separator ""
        opts.separator "Glue is a swiss army knife of security analysis tools."
        opts.separator "It has built in support for static analysis, AV, fim, and "
        opts.separator "is being extended to be used for analyzing all kinds of "
        opts.separator "projects, images or file systems."
        opts.separator ""
        opts.separator "Glue also features filters to perform deduplication "
        opts.separator "and the abilty to handle false positives."
        opts.separator ""
        opts.separator "See also the docker image."
        opts.separator ""

        opts.separator "Control options:"

        opts.on "-T", "--target PATH", "Specify target" do |target|
          options[:target] = path
        end

        opts.on "-q", "--[no-]quiet", "Suppress informational messages" do |quiet|
          options[:quiet] = quiet
        end

        opts.on( "-z", "--exit-on-warn [severity_threshold]", "Exit code is non-zero if warnings found. If [severity_threshold] is specified, the highest severity must be greater than or equal to [severity_threshold] to tigger the non-zero exit code, which will equal the highest severity.") do |severity_threshold|
          options[:exit_on_warn] = true
          if severity_threshold
            puts "Setting severity_threshold to #{severity_threshold}"
            
          end
          options[:severity_threshold] = severity_threshold
        end

        opts.separator ""
        opts.separator "Scanning options:"

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
                [:text, :csv, :json, :jira, :pivotal, :teamcity],
                [:text, :csv, :json, :jira, :pivotal, :slack, :teamcity],
                "Specify output formats. Default is text" do |type|
          options[:output_format] = type
        end
        opts.on "-o", "--output FILE", "Specify file for output. Defaults to stdout." do |file|
          options[:output_file] = file
        end
        opts.on "-L LOGFILE", "--logfile LOGFILE", "Write full Glue log to LOGFILE" do |file|
          options[:logfile] = file
        end

        opts.separator ""
        opts.separator "Bug tracking integration options:"

        opts.separator ""
        opts.separator "JIRA options:"
        opts.on "--jira-api-url URL", "Specify the jira rest api endpoint. Eg. jemurai.atlassian.net." do |url|
          options[:jira_api_url] = url
        end
        opts.on "--jira-api-context CONTEXT", "Specify the context (part after the base url if existing) for the rest api endpoint.  Defaults to empty." do |context|
          options[:jira_api_context] = context
        end
        opts.on "--jira-username USER", "Specify the user to get to Jira.  (To be used for basic authentication - be sure it is HTTPS)" do |user|
          options[:jira_username] = user
        end
        opts.on "--jira-password PASSWORD", "Specify the password to use to get to Jira." do |password|
          options[:jira_password] = password
        end
        opts.on "--jira-project PROJECT", "Specify the jira project to create issues in. If issue looks like APPS-13, this should be APPS." do |project|
          options[:jira_project] = project
        end
        opts.on "--jira-component COMPONENT", "Specify the JIRA component to use." do |component|
          options[:jira_component] = component
        end
        opts.on "--jira-epic-field-id EPIC_FIELD_ID", "(optional) Specify the custom field ID used to link to the JIRA epic, e.g. customfield_10001." do |jira_epic_field_id|
          options[:jira_epic_field_id] = jira_epic_field_id
        end
        opts.on "--jira-epic EPIC", "(optional) Specify the ID of the JIRA epic, e.g. MYPROJ-1005." do |jira_epic|
          options[:jira_epic] = jira_epic
        end
        opts.on "--jira-skip-fields FIELDS", "Specify any JIRA fields to skip (separate with commas)." do |skip_fields|
          options[:jira_skip_fields] = skip_fields
        end
        opts.on "--jira-default-priority PRIORITY", "Specify a default priority for JIRA issues. This will override the mapping of severity to priority." do |default_priority|
          options[:jira_default_priority] = default_priority
        end

        opts.separator ""
        opts.separator "Pivotal options:"
        opts.on "--pivotal-api-url URL", "Specify the pivotal rest api endpoint. Eg. jemurai.atlassian.net." do |url|
          options[:pivotal_api_url] = url
        end
        opts.on "--pivotal-token TOKEN", "Specify the token to use to get to Pivotal." do |token|
          options[:pivotal_token] = token
        end
        opts.on "--pivotal-project PROJECT_ID", "Specify the pivotal project to create issues in." do |project|
          options[:pivotal_project] = project
        end

        opts.separator ""
        opts.separator "Scanning integration options:"

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
        opts.on "--zap-passive-mode", "Specify the port ZAP is running on." do
            options[:zap_passive_mode] = true
          end

        opts.separator ""
        opts.separator "Scout options:"
        opts.on "--scout-aws-key key", "Specify the AWS Key to use with Scout" do |scout_aws_key|
          options[:scout_aws_key] = scout_aws_key
        end
        opts.on "--scout-aws-secret secret", "Specify the AWS secret to use with Scout." do |scout_aws_secret|
          options[:scout_aws_secret] = scout_aws_secret
        end
        opts.on "--scout-aws-level level", "Specify the level to report from Scout." do |scout_level|
          options[:scout_level] = scout_level
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
        opts.on "--checkmarx-exclude paths", "Specify the paths of folders (relative to target) to exclude from scan" do |exclude|
          options[:checkmarx_exclude] = exclude
        end
        opts.on "--checkmarx-incremental", "Specify the full path of the Checkmarx project for this scan" do
          options[:checkmarx_incremental] = true
        end
        opts.on "--checkmarx-preset", "Specify the preset to use for the scan this project" do |preset|
          options[:checkmarx_preset] = preset
        end
        opts.on "--checkmarx-path path", "Specify the full path to runCxConsole.sh" do |path|
          options[:checkmarx_path] = path
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
        opts.separator "OWASP Dependency Check options:"
        opts.on "--owasp-dep-check-path PATH", "The full path to the OWASP Dependency Check script" do |path|
          options[:owasp_dep_check_path] = path
        end

        opts.on "--owasp-dep-check-log", "Include verbose logging from OWAP Dependency Check" do
          options[:owasp_dep_check_log] = true
        end

        opts.on "--owasp-suppression PATH", "The path to the OWASP Dependency Check XML suppression file" do |path|
          Glue.debug "Setting suppression file to #{path}"
          options[:owasp_dep_check_suppression] = path
        end

        opts.on "--sbt-path PATH", "The full path to sbt (optional)" do |path|
          options[:sbt_path] = path
        end

        opts.on "--scala-project", "OWAP Dependency Check for Scala project" do
          options[:scala_project] = true
        end

        opts.separator ""
        opts.separator "Burp options:"
        opts.on "--burp-xml-path BURL_XML_PATH", "Burp XML Path" do |burp_xml_path|
          options[:burp_xml_path] = burp_xml_path
        end

        opts.separator ""
        opts.separator "Contrast Security options:"
        opts.on "--contrast-api-key API_KEY", "Contrast API key" do |contrast_api_key|
          options[:contrast_api_key] = contrast_api_key
        end
        opts.on "--contrast-service-key SERVICE_KEY", "Contrast service key" do |contrast_service_key|
          options[:contrast_service_key] = contrast_service_key
        end
        opts.on "--contrast-org-id ORG_ID", "Contrast organization ID" do |contrast_org_id|
          options[:contrast_org_id] = contrast_org_id
        end
        opts.on "--contrast-user-name USER_NAME", "Contrast user name" do |contrast_user_name|
          options[:contrast_user_name] = contrast_user_name
        end
        opts.on "--contrast-app-name APP_NAME", "Contrast app name" do |contrast_app_name|
          options[:contrast_app_name] = contrast_app_name
        end
        opts.on "--contrast-update-closed-jira-issues APP_NAME", "Only update Contrast status for closed JIRA issues?" do |contrast_update_closed_jira_issues|
          options[:contrast_update_closed_jira_issues] = true
        end
        opts.on "--contrast-min-severity MIN_SEVERITY", "Contrast minimum severity" do |contrast_min_severity|
          options[:minimum_contrast_severity] = contrast_min_severity
        end
        opts.on "--contrast-filter-options OPT1=VAL1,OPT2=VAL2", "Contrast vulnerability filter options",
          "Filter Contrast results using any of the query parameter options exposed by the .../traces/{appId}/ids endpoint. Each filter and its value should be in a KEY=VAL format. Values that require multiple entries can be separated with a semicolon: servers=server1;server2;server3." do |contrast_filter_options|
          options[:contrast_filter_options] = contrast_filter_options
        end

        opts.on "--finding-file-path PATH", "the path to the file with existing issues" do |path|
            options[:finding_file_path] = path
        end

        opts.separator ""

        opts.separator "TeamCity reporter options"
        opts.on "--teamcity-min-level LEVEL", "Report test failure for all findings above this level" do |teamcity_min_level|
          options[:teamcity_min_level] = teamcity_min_level.to_i()
        end

        opts.separator "Slack reporter options:"
        opts.on "--slack-token TOKEN", "Bot token" do |slack_token|
          options[:slack_token] = slack_token
        end
        opts.on "--slack-channel CHANNEL", "The channel/user to post to" do |slack_channel|
          options[:slack_channel] = slack_channel
        end
        opts.on "--slack-post-as-bot", "When posting to user, set this flag to post on the bot channel for this users",
        "Otherwise, the bot will post to the user's slackbot." do |slack_post_as_user|
          options[:slack_post_as_user] = slack_post_as_user
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
        opts.separator "Other Useful Options:"
        opts.on "-k", "--tasks", "List all available tasks" do
          options[:list_checks] = true
        end
        opts.on "--optional-checks", "List optional checks" do
          options[:list_optional_checks] = true
        end
        opts.on "-v", "--version", "Show Glue version" do
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
