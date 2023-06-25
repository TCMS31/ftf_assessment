# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ciphers::Registry do
  it 'resolves the built-in rot13 cipher' do
    expect(described_class.fetch('rot13')).to eq(Ciphers::Rot13)
  end

  it 'reports which ciphers are registered' do
    expect(described_class.names).to include('rot13')
    expect(described_class).to be_registered('rot13')
    expect(described_class).not_to be_registered('atbash')
  end

  it 'raises for an unknown cipher' do
    expect { described_class.fetch('atbash') }
      .to raise_error(described_class::UnknownCipherError, /atbash/)
  end

  it 'refuses to register something that cannot encrypt' do
    expect { described_class.register('broken', Object.new) }.to raise_error(ArgumentError)
  end

  # This is the extensibility claim in the README, asserted rather than asserted-in-prose.
  it 'accepts a new cipher without any other change' do
    atbash = Module.new do
      def self.encrypt(text) = text.tr('a-z', 'zyxwvutsrqponmlkjihgfedcba')
    end

    described_class.register('atbash', atbash)
    expect(described_class.fetch('atbash').encrypt('abc')).to eq('zyx')
  ensure
    described_class.instance_variable_get(:@ciphers).delete('atbash')
  end
end
