# frozen_string_literal: true

# One encrypted string, paired with the cipher that produced it.
#
# `enc_type` stores the cipher's registry name rather than a boolean or a Rails
# enum, so registering a new cipher in Ciphers::Registry needs no migration and
# no change here.
class StringEncryption < ApplicationRecord
  validates :original_string, presence: true
  validates :encrypted_string, presence: true
  validates :enc_type, presence: true
  validates :enc_type, inclusion: { in: ->(_record) { Ciphers::Registry.names } }, allow_blank: true
end
