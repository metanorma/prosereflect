# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::HardBreak do
  describe 'initialization' do
    it 'initializes as a hard_break node' do
      break_node = described_class.new({ 'type' => 'hard_break' })
      expect(break_node.type).to eq('hard_break')
    end
  end

  describe '.create' do
    it 'creates a hard break' do
      break_node = described_class.create
      expect(break_node).to be_a(described_class)
      expect(break_node.type).to eq('hard_break')
    end

    it 'creates a hard break with marks' do
      marks = [{ 'type' => 'bold' }]
      break_node = described_class.create(marks)
      expect(break_node.marks).to eq(marks)
    end
  end

  describe '#text_content' do
    it 'returns a newline character' do
      break_node = described_class.create
      expect(break_node.text_content).to eq("\n")
    end
  end

  describe '#to_h' do
    it 'generates hash representation' do
      break_node = described_class.create
      hash = break_node.to_h
      expect(hash).to eq({ 'type' => 'hard_break' })
    end

    it 'includes marks in hash representation' do
      marks = [{ 'type' => 'italic' }]
      break_node = described_class.create(marks)
      hash = break_node.to_h
      expect(hash).to eq({
                           'type' => 'hard_break',
                           'marks' => marks
                         })
    end
  end
end
