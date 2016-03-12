require 'pipeline/filters/base_filter'

class Pipeline::ZAPCondensingFilter < Pipeline::BaseFilter
  
  Pipeline::Filters.add self
  
  def initialize
    @name = "ZAP Condensing Filter"
    @description = "Consolidate N ZAP warnings to one per issue type."
  end

  def filter tracker
    Pipeline.debug "Have #{tracker.findings.count} items pre ZAP filter."
    tracker.findings.each do |finding|
      if zap? finding
        if xframe? finding
          record tracker,finding
        elsif xcontenttypeoptions? finding
          record tracker, finding
        elsif dirbrowsing? finding
          record tracker, finding
        elsif xxssprotection? finding
          record tracker, finding
        end
      end
    end
    Pipeline.debug "Have #{tracker.findings.count} items post ZAP filter."
  end

  def zap? finding
    if finding.source =~ /\AZAP/
      return true
    end
    return false
  end

  def xframe? finding
    if finding.description == "X-Frame-Options header is not included in the HTTP response to protect against 'ClickJacking' attacks."
      return true
    end
    return false
  end

  def xcontenttypeoptions? finding
    if finding.description == "The Anti-MIME-Sniffing header X-Content-Type-Options was not set to 'nosniff'. This allows older versions of Internet Explorer and Chrome to perform MIME-sniffing on the response body, potentially causing the response body to be interpreted and displayed as a content type other than the declared content type. Current (early 2014) and legacy versions of Firefox will use the declared content type (if one is set), rather than performing MIME-sniffing."
      return true
    end
    return false
  end

  def dirbrowsing? finding
    if finding.description == "It is possible to view the directory listing.  Directory listing may reveal hidden scripts, include files , backup source files etc which be accessed to read sensitive information."
      return true
    end
    return false
  end

  def xxssprotection? finding
    if finding.description == "Web Browser XSS Protection is not enabled, or is disabled by the configuration of the 'X-XSS-Protection' HTTP response header on the web server"
      return true
    end
    return false
  end

  # Is it always true that the findings will be on the same site?
  # For now, we can assume that.
  # Note that this may not be an efficient way to to do this, but it seems to work as a first pass.
  def record tracker, finding
    tracker.findings.delete_if do |to_delete|
      to_delete.description == finding.description
    end
    finding.detail << "\n\t** Consolidated ** - Potentially identified in > 1 spot."  # Make sure to note that there were 
    tracker.findings.push finding 
  end

end
