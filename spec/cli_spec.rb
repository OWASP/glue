require 'spec_helper'

RSpec.describe 'CLI HELP', :type => :aruba do
  before(:each) { run('glue -h') }
  it { expect(last_command_started).to be_successfully_executed }
  it { expect(last_command_started).to have_output /Glue is a swiss army knife of security analysis tools/ }
end

RSpec.describe 'CLI Version', :type => :aruba do
  before(:each) { run('glue -v') }
  it { expect(last_command_started).to be_successfully_executed }
  it { expect(last_command_started).to have_output /Glue 0.9.0/ }
end

RSpec.describe 'CLI NONSENSE', :type => :aruba do
  before(:each) { run('glue -nonsense') }
  it { expect(last_command_started).to have_output /Invalid option: -nonsense/ }
  it { expect(last_command_started).to have_output /Please see `glue --help` for valid options/ }
end
