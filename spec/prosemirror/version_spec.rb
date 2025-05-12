# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosemirror::VERSION do
  it 'has a version number' do
    expect(Prosemirror::VERSION).not_to be nil
    expect(Prosemirror::VERSION).to be_a(String)
    expect(Prosemirror::VERSION).to match(/\d+\.\d+\.\d+/)
  end
end
