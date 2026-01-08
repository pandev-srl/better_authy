# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::Engine do
  it "is a Rails::Engine" do
    expect(described_class.superclass).to eq(::Rails::Engine)
  end

  it "isolates namespace to BetterAuthy" do
    expect(described_class.isolated).to be(true)
  end

  it "configures rspec as test framework for generators" do
    generator_config = described_class.config.generators
    expect(generator_config.options[:rails][:test_framework]).to eq(:rspec)
  end
end
