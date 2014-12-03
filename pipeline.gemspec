require './lib/pipeline/version'

Gem::Specification.new do |s|
  s.name = %q{pipeline}
  s.version = Pipeline::Version
  s.authors = ["Matt Konda and Jon Rose"]
  s.email = "jrose@redsky.com"
  s.summary = "Security scanner for the cloud."
  s.description = "Pipeline detects security vulnerabilities in virtual images."
  s.homepage = "http://redsky.com"
  s.files = ["bin/pipeline", "CHANGES", "FEATURES", "README.md"] + Dir["lib/**/*"]
  s.executables = ["pipeline"]
  s.license = "Copyright Redsky and Jemurai."
  s.add_dependency "terminal-table", "~>1.4"
  s.add_dependency "fastercsv", "~>1.5"
  s.add_dependency "highline", "~>1.6.20"
  s.add_dependency "multi_json", "~>1.2"
end
