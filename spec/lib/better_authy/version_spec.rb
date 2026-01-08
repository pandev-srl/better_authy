# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BetterAuthy::VERSION" do
  it "is defined" do
    expect(BetterAuthy::VERSION).to be_a(String)
  end

  it "follows semantic versioning format" do
    expect(BetterAuthy::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
