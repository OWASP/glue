require 'json'

class Pipeline::Finding
  attr_reader :appname
  attr_reader :timestamp
  attr_reader :severity
  attr_reader :source
  attr_reader :description
  attr_reader :detail
  attr_reader :fingerprint

  def initialize(appname, description, detail, source, severity, fingerprint)
    @appname = appname
    @timestamp = Time.now
    @description = description
    @detail = detail
    @source = source
    @stringsrc = source.to_s
    @severity = severity
    @fingerprint = fingerprint
  end

  def to_string
    s = "Finding: #{@appname}"
    s << "\n\tDescription: #{@description}"
    s << "\n\tTimestamp: #{@timestamp}"
    s << "\n\tSource: #{@stringsrc}"
    s << "\n\tSeverity: #{@severity}"
    s << "\n\tFingerprint:  #{@fingerprint}"
    s << "\n\tDetail:  #{@detail}"
    s
  end

  def to_csv
    s = "#{@appname},#{@description},#{@timestamp},#{@source},#{@severity},#{@fingerprint},#{@detail}\n"
    s
  end

  def to_json
    json = {
      'appname' => @appname,
      'description' => @description,
      'fingerprint' => @fingerprint,
      'detail' => @detail,
      'source' => @source,
      'severity' => @severity,
      'timestamp' => @timestamp
    }.to_json
    json
  end
end
