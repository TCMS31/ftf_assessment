# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceResult do
  it 'builds a success' do
    result = described_class.success({ a: 1 })

    expect(result).to be_success
    expect(result).not_to be_failure
    expect(result.status).to eq(:ok)
    expect(result.to_h).to eq(a: 1, error: nil)
  end

  it 'builds a failure with a default 422' do
    result = described_class.failure('nope', { a: 1 })

    expect(result).to be_failure
    expect(result.status).to eq(:unprocessable_entity)
    expect(result.to_h).to eq(a: 1, error: 'nope')
  end

  it 'accepts an explicit status' do
    expect(described_class.failure('nope', {}, status: :bad_gateway).status).to eq(:bad_gateway)
  end

  it 'is immutable' do
    expect(described_class.success({ a: 1 })).to be_frozen
  end
end
