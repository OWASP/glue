require 'glue/filters/base_filter'
require 'jira-ruby'
require 'date'

class Glue::FileFilter < Glue::BaseFilter

  Glue::Filters.add self

  def initialize
    @name = "File Filter"
    @description = "Checks that each issue against exisiting issues status file"
  end

  def filter tracker
    if (tracker.options[:finding_file_path].nil?)
        return
    end
    exisiting_finding = {}
    if (File.exist? tracker.options[:finding_file_path])
        exisiting_finding = JSON.parse!(File.read tracker.options[:finding_file_path])
    end
    
    potential_findings = Array.new(tracker.findings)
    tracker.findings.clear
    
    for finding in potential_findings do
        if (!exisiting_finding.key? finding.fingerprint)
            exisiting_finding[finding.fingerprint] = "new"
        end

        if exisiting_finding[finding.fingerprint] == "new" 
            tracker.report finding
        elsif exisiting_finding[finding.fingerprint].starts_with? "postpone:"
            date_raw = exisiting_finding[finding.fingerprint].split("postpone:")[1]
            begin
                date = Date.strptime(date_raw, "%d-%m-%Y")
                if (date <= Date.today)
                    tracker.report finding
                end
            rescue => e
                Glue.error "failed to parse date: #{e}"
            end
        end
    end

    File.open(tracker.options[:finding_file_path], 'w') {|f| f << JSON.pretty_generate(exisiting_finding)}

    return tracker.findings
  end


end
