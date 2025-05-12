# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::VERSION do
  it 'has a version number' do
    expect(Prosereflect::VERSION).not_to be nil
    expect(Prosereflect::VERSION).to be_a(String)
    expect(Prosereflect::VERSION).to match(/\d+\.\d+\.\d+/)
  end
end
