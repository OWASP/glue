require 'spec_helper'

require 'glue/tasks'
require 'glue/tasks/sfl'

describe "For Glue::SFL.patterns:" do
  before(:all) do
    @example_pattern = {
      "part" => "filename",
      "type" => "regex",
      "pattern" => "\\A\\.?(bash|zsh)rc\\z",
      "caption" => "Shell configuration file",
      "description" => "Shell configuration files might contain..."
    }

    @example_keys = @example_pattern.keys
    @valid_filepath_parts = %w[filename extension path]
    @valid_match_types = %w[match regex]
  end

  Glue::SFL.patterns.each do |pattern|
    context "the pattern #{pattern}" do
      it "has valid keys" do
        expect(pattern.keys).to eq(@example_keys)
      end

      it "has String values for all keys (or 'nil' for 'description')" do
        is_valid = pattern.all? do |key, value|
          value.is_a?(String) || (key == 'description' && value.nil?)
        end

        expect(is_valid).to eq(true)
      end

      it "has a valid pattern['part']" do
        expect(pattern['part']).to be_included_in(*@valid_filepath_parts)
      end

      it "has a valid pattern['type']" do
        expect(pattern['type']).to be_included_in(*@valid_match_types)
      end
    end
  end

  def be_included_in(first_value, *rest)
    # https://github.com/rspec/rspec-expectations/issues/760
    rest.inject(eq(first_value)) do |matcher, value|
      matcher.or eq(value)
    end
  end
end
