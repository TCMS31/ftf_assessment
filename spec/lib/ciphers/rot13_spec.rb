# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ciphers::Rot13 do
  it 'rotates letters thirteen places' do
    expect(described_class.encrypt('Hello, World!')).to eq('Uryyb, Jbeyq!')
  end

  it 'leaves digits, punctuation and whitespace untouched' do
    expect(described_class.encrypt('42 -- ok!')).to eq('42 -- bx!')
  end

  it 'is its own inverse' do
    expect(described_class.decrypt(described_class.encrypt('Round trip'))).to eq('Round trip')
  end

  it 'returns an empty string unchanged' do
    expect(described_class.encrypt('')).to eq('')
  end
end
