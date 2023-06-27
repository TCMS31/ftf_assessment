# frozen_string_literal: true

module Ciphers
  # ROT13: rotate every ASCII letter 13 places through the alphabet. Because 13
  # is half of 26 the transform is its own inverse, so `decrypt` is `encrypt`.
  # Non-letters are passed through untouched.
  module Rot13
    NAME = 'rot13'
    PLAIN = 'a-zA-Z'
    ROTATED = 'n-za-mN-ZA-M'

    module_function

    # @param text [String]
    # @return [String]
    def encrypt(text)
      text.tr(PLAIN, ROTATED)
    end

    # ROT13 is symmetric.
    def decrypt(text)
      encrypt(text)
    end
  end
end
