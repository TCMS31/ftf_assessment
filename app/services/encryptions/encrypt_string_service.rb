# frozen_string_literal: true

module Encryptions
  # Encrypts a string with a named cipher and records the result.
  #
  # The cipher itself lives in `app/lib/ciphers` and knows nothing about Rails;
  # this class owns the validation, the persistence and the result shape.
  class EncryptStringService < ApplicationService
    # @param original_string [Object] untrusted input straight off the request body
    # @param cipher_name [String] a key registered in {Ciphers::Registry}
    def initialize(original_string:, cipher_name: Ciphers::Rot13::NAME)
      @original_string = original_string
      @cipher_name = cipher_name
      super()
    end

    def call
      invalid = validation_error
      return failure(invalid) if invalid

      persist(cipher.encrypt(original_string))
    end

    private

    attr_reader :original_string, :cipher_name

    def cipher
      @cipher ||= Ciphers::Registry.fetch(cipher_name)
    end

    # Returns a user-facing message, or nil when the input is usable.
    #
    # The `is_a?(String)` check is the one that matters: a JSON body of
    # `{"original_string": 12345}` used to reach `Integer#tr` and blow up with a
    # NoMethodError that was rendered back to the caller verbatim.
    def validation_error
      return I18n.t('errors.encryption.parameter_missing') unless original_string.is_a?(String)
      return I18n.t('errors.encryption.parameter_missing') if original_string.blank?
      unless Ciphers::Registry.registered?(cipher_name)
        return I18n.t('errors.encryption.unknown_cipher', name: cipher_name)
      end

      nil
    end

    def persist(encrypted_string)
      record = StringEncryption.create!(original_string: original_string,
                                        encrypted_string: encrypted_string,
                                        enc_type: cipher_name)

      ServiceResult.success({ original_string: record.original_string,
                              encrypted_string: record.encrypted_string })
    end

    def failure(message)
      ServiceResult.failure(message,
                            { original_string: original_string.is_a?(String) ? original_string : nil,
                              encrypted_string: nil })
    end
  end
end
