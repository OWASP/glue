require 'spec_helper'
require 'json'

RSpec.describe 'Parse Scout JSON' do
  file = File.open("#{File.expand_path(File.dirname(__FILE__))}/scout_data.json", "rb")
  result = file.read
  start = result.index('{')
  result = result.slice(start,result.size)
  #puts "Result: #{result}"
  it {
    expect( JSON.parse(result) )
    json = JSON.parse(result)
    count = 0
    findingcount = 0
    dangercount = 0
    json["services"].each do |name, servicesjson|
      count = count + 1
      # puts "Count:  #{count}"
      # puts name
      if servicesjson["findings"] then
        servicesjson["findings"].each do |findingname, detail|
          findingcount = findingcount + 1
          # puts "\t#{findingname}"
          # puts "\t\t#{detail["description"]}"
          # puts "\t\t#{detail["level"]}"       
          if detail["level"] == "danger" then
            dangercount = dangercount + 1
          end
        end
      end
    end
    # puts "Finding count #{dangercount}"
    expect(findingcount).to be == 109
    expect(dangercount).to be == 75
    expect(count).to be == 15
  }
end
