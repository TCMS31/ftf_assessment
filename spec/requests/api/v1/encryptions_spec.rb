# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/encryptions/rot13' do
  def post_rot13(body)
    post '/api/v1/encryptions/rot13', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
  end

  it 'encrypts and persists the string' do
    expect { post_rot13({ original_string: 'Hello, world!' }.to_json) }
      .to change(StringEncryption, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('original_string' => 'Hello, world!',
                                       'encrypted_string' => 'Uryyb, jbeyq!',
                                       'error' => nil)
  end

  it 'rejects a missing original_string' do
    post_rot13({}.to_json)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Missing parameter or its value: original_string')
  end

  it 'rejects an empty body' do
    post_rot13(nil)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq('error' => 'Request body cannot be empty')
  end

  it 'rejects a malformed JSON body' do
    post_rot13('{not json')

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Request body cannot be empty')
  end

  it 'rejects a JSON array body' do
    post_rot13('["a","b"]')

    expect(response).to have_http_status(:unprocessable_entity)
  end

  # Regression: a non-string value used to reach Integer#tr, and the resulting
  # NoMethodError — including the source line `str.tr('a-zA-Z', ...)` — was
  # echoed straight back to the caller.
  it 'rejects a non-string original_string without leaking internals' do
    expect { post_rot13({ original_string: 12_345 }.to_json) }.not_to change(StringEncryption, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('Missing parameter or its value: original_string')
    expect(response.body).not_to include('NoMethodError')
  end

  context 'when persistence blows up' do
    before { allow(StringEncryption).to receive(:create!).and_raise(StandardError, 'PG::ConnectionBad: fatal') }

    it 'returns a generic 500 and logs the detail' do
      allow(Rails.logger).to receive(:error)

      post_rot13({ original_string: 'Hello' }.to_json)

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body).to eq('error' => 'Something went wrong. Please try again.')
      expect(response.body).not_to include('PG::ConnectionBad')
      expect(Rails.logger).to have_received(:error).with(/PG::ConnectionBad/)
    end
  end

  it 'caps how much of the request body it will read' do
    limit = Api::V1::EncryptionsController::MAX_BODY_BYTES
    post_rot13({ original_string: 'a' * (limit + 1_000) }.to_json)

    # The truncated read yields invalid JSON, which is refused rather than
    # buffering an unbounded body into memory.
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
