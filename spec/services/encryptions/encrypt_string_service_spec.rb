# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Encryptions::EncryptStringService do
  describe '#call' do
    context 'with a valid string' do
      it 'returns a success result carrying the ciphertext' do
        result = described_class.call(original_string: 'Hello World')

        expect(result).to be_success
        expect(result.status).to eq(:ok)
        expect(result.data).to eq(original_string: 'Hello World', encrypted_string: 'Uryyb Jbeyq')
        expect(result.error).to be_nil
      end

      it 'persists the pair with its cipher name' do
        expect { described_class.call(original_string: 'Hello World') }
          .to change(StringEncryption, :count).by(1)

        record = StringEncryption.last
        expect(record).to have_attributes(original_string: 'Hello World',
                                          encrypted_string: 'Uryyb Jbeyq',
                                          enc_type: 'rot13')
      end
    end

    context 'with a blank string' do
      it 'fails without touching the database' do
        expect { described_class.call(original_string: '') }.not_to change(StringEncryption, :count)
      end

      it 'returns the missing-parameter error' do
        result = described_class.call(original_string: '')

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.error).to eq('Missing parameter or its value: original_string')
        expect(result.data).to eq(original_string: '', encrypted_string: nil)
      end
    end

    # Regression: a JSON body of {"original_string": 12345} reached Integer#tr
    # and raised NoMethodError, which was rendered back to the API caller with
    # the offending line of Ruby source in it.
    [12_345, nil, ['a'], { 'a' => 1 }, true].each do |value|
      it "rejects a #{value.class} instead of crashing" do
        result = nil
        expect { result = described_class.call(original_string: value) }
          .not_to change(StringEncryption, :count)

        expect(result).to be_failure
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.data[:original_string]).to be_nil
      end
    end

    context 'with an unregistered cipher' do
      it 'fails cleanly' do
        result = described_class.call(original_string: 'hi', cipher_name: 'atbash')

        expect(result).to be_failure
        expect(result.error).to include('atbash')
      end
    end

    context 'when the database rejects the record' do
      it 'lets the error propagate for the controller to handle' do
        allow(StringEncryption).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

        expect { described_class.call(original_string: 'hi') }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
