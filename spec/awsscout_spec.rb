# require 'spec_helper'

# require 'glue/tasks'
# require 'glue/tracker'
# require 'glue/tasks/scout2'
# require 'glue'

# def get_scouter
#   options = {}
#   trigger = "abc"
#   tracker = Glue::Tracker.new(options)
#   scouter = Glue::Scout.new(@trigger, @tracker)
#   scouter
# end

# RSpec.describe "Test AWS Scout Glue Task Supports" do
#   scouter = get_scouter
#   result = scouter.supported?
#   it {
#     expect(result).to be == true
#   }
# end

# RSpec.describe "Test analyze on main scout_data.json file" do
#   scouter = get_scouter
#   scouter.result = File.open("#{File.expand_path(File.dirname(__FILE__))}/scout_data.json", "rb")
#   scouter.analyze
#   #  scouter.
# end


