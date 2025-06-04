# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect::User do
  let(:user) { described_class.new }

  describe '#initialize' do
    it 'creates a user mention node with empty content' do
      expect(user.content).to eq([])
    end
  end

  describe '#id' do
    it 'gets and sets the user id' do
      user.id = '123'
      expect(user.id).to eq('123')
    end

    it 'gets id from attrs' do
      user = described_class.new(attrs: { 'id' => '456' })
      expect(user.id).to eq('456')
    end
  end

  describe '#add_child' do
    it 'raises NotImplementedError' do
      expect { user.add_child(double) }.to raise_error(NotImplementedError, 'User mention nodes cannot have children')
    end
  end

  describe '#to_h' do
    it 'serializes correctly' do
      user.id = '789'
      expect(user.to_h).to eq({
                                'type' => 'user',
                                'attrs' => { 'id' => '789' },
                                'content' => []
                              })
    end
  end

  describe 'integration with Document' do
    it 'can be added to a document' do
      document = Prosereflect::Document.create
      user = document.add_user('123')

      expect(user).to be_a(described_class)
      expect(user.id).to eq('123')
      expect(document.content.size).to eq(1)
      expect(document.content.first).to be_a(described_class)
    end
  end

  describe 'HTML conversion' do
    it 'converts to HTML correctly' do
      document = Prosereflect::Document.create
      document.add_user('123')

      html = Prosereflect::Output::Html.convert(document)
      expect(html).to eq('<user-mention data-id="123"></user-mention>')
    end

    it 'parses from HTML correctly' do
      html = '<user-mention data-id="123"></user-mention>'
      document = Prosereflect::Input::Html.parse(html)

      expect(document.content.size).to eq(1)
      expect(document.content.first).to be_a(described_class)
      expect(document.content.first.id).to eq('123')
    end
  end
end
