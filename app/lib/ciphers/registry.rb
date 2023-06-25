# frozen_string_literal: true

module Ciphers
  # Lookup table of the ciphers the API exposes.
  #
  # This is the extension seam. Adding a cipher is one new module under
  # `app/lib/ciphers/` that responds to `.encrypt(String)` plus one line here;
  # nothing in the controller, service or persistence layer changes, because the
  # cipher name is what gets stored in `string_encryptions.enc_type`.
  #
  #   Ciphers::Registry.register('atbash', Ciphers::Atbash)
  module Registry
    class UnknownCipherError < StandardError; end

    @ciphers = {}

    class << self
      # @param name [String] the value persisted in `enc_type`
      # @param cipher [#encrypt] anything responding to `encrypt(String) => String`
      def register(name, cipher)
        raise ArgumentError, "cipher #{name.inspect} must respond to #encrypt" unless cipher.respond_to?(:encrypt)

        @ciphers[name.to_s] = cipher
      end

      # @raise [UnknownCipherError] when nothing is registered under +name+
      def fetch(name)
        @ciphers.fetch(name.to_s) { raise UnknownCipherError, "unknown cipher: #{name}" }
      end

      def registered?(name)
        @ciphers.key?(name.to_s)
      end

      def names
        @ciphers.keys
      end
    end

    register(Rot13::NAME, Rot13)
  end
end
