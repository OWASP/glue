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
        opts.separator "images or file systems."
        opts.separator ""
        opts.separator "Pipeline also features deduplication and the abilty to handle "
        opts.separator "false positives."
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
          checks.each_with_index do |s, index|
            if s[0,5] != "Check"
              checks[index] = "Check" << s
            end
          end

          options[:run_checks] ||= Set.new
          options[:run_checks].merge checks
        end

        opts.on "-x", "--except Check1,Check2,etc", Array, "Skip the specified checks" do |skip|
          skip.each do |s|
            if s[0,5] != "Check"
              s = "Check" << s
            end

            options[:skip_checks] ||= Set.new
            options[:skip_checks] << s
          end
        end

        opts.on "-l", "--labels Label1,Label2,etc", Array, "Run the checks with the supplied labels" do |labels|
          options[:labels] ||= Set.new
          options[:labels].merge labels
        end

        opts.on "--add-checks-path path1,path2,etc", Array, "A directory containing additional out-of-tree checks to run" do |paths|
          options[:additional_checks_path] ||= Set.new
          options[:additional_checks_path].merge paths.map {|p| File.expand_path p}
        end

        opts.separator ""
        opts.separator "Output options:"

        opts.on "-d", "--debug", "Lots of output" do
          options[:debug] = true
        end

        opts.on "-f",
                "--format TYPE",
                [:text, :html, :csv, :tabs, :json, :markdown],
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

        opts.on "-o", "--output FILE", "Specify files for output. Defaults to stdout. Multiple '-o's allowed" do |file|
          options[:output_files] ||= []
          options[:output_files].push(file)
        end

        opts.on "--summary", "Only output summary of warnings" do
          options[:summary_only] = true
        end

        opts.on "--compare FILE", "Compare the results of a previous brakeman scan (only JSON is supported)" do |file|
          options[:previous_results_json] = File.expand_path(file)
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
