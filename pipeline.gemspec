require './lib/pipeline/version'

Gem::Specification.new do |s|
  s.name = %q{pipeline}
  s.version = Pipeline::Version
  s.authors = ["Matt Konda"]
  s.email = "mkonda@jemurai.com"
  s.summary = "Security scanner for the cloud."
  s.description = "Pipeline detects security vulnerabilities in code."
  s.homepage = "http://jemurai.com"
  s.files = ["bin/pipeline", "CHANGES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["pipeline"]
  s.license = "Apache 2"
  s.add_dependency "terminal-table", ">= 1.4"
  s.add_dependency "fastercsv", ">= 1.5"
  s.add_dependency "highline", ">= 1.6.20"
  s.add_dependency "multi_json", ">= 1.2"
  s.add_dependency "bundler-audit", ">= 0.3.1"
  s.add_dependency "brakeman", ">= 3.0.5"
  s.add_dependency "curb", ">= 0.8.8"
  s.add_dependency "jsonpath", ">= 0.5.7"
end
