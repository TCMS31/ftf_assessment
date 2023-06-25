# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StringEncryption do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:original_string) }
    it { is_expected.to validate_presence_of(:encrypted_string) }
    it { is_expected.to validate_presence_of(:enc_type) }

    it 'accepts a cipher name that is registered' do
      record = described_class.new(original_string: 'a', encrypted_string: 'n', enc_type: 'rot13')

      expect(record).to be_valid
    end

    # The registry is the single source of truth for cipher names; the database
    # must not accumulate rows naming a cipher that cannot decrypt them.
    it 'rejects a cipher name that is not registered' do
      record = described_class.new(original_string: 'a', encrypted_string: 'n', enc_type: 'atbash')

      expect(record).not_to be_valid
      expect(record.errors[:enc_type]).to be_present
    end
  end
end
