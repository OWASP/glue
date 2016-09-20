require './lib/glue/version'

Gem::Specification.new do |s|
  s.name = %q{owasp-glue}
  s.version = Glue::Version
  s.authors = ["Matt Konda", "Alex Lock", "Rafa Perez"]
  s.email = "matt.konda@owasp.org"
  s.summary = "Security toolchain for software build automation."
  s.description = "Glue detects security vulnerabilities in code."
  s.homepage = "http://github.com/OWASP/glue"
  s.files = ["bin/glue", "CHANGES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["glue"]
  s.license = "Apache 2"
  s.add_dependency "terminal-table", ">= 1.4"
  s.add_dependency "fastercsv", ">= 1.5"
  s.add_dependency "highline", ">= 1.6.20"
  s.add_dependency "multi_json", ">= 1.2"
  s.add_dependency "bundler-audit", ">= 0.3.1"
  s.add_dependency "brakeman", ">= 3.0.5"
  s.add_dependency "curb", ">= 0.8.8"
  s.add_dependency "jsonpath", ">= 0.5.7"
  s.add_dependency "nokogiri", ">=1.6.6.2"
  s.add_dependency "rake"
  s.add_dependency "dawnscanner", ">= 1.6.0"
  s.add_dependency "redcarpet"
  s.add_dependency "jira-ruby"

  s.add_development_dependency "pry"
  s.add_development_dependency "pry-byebug"
end
