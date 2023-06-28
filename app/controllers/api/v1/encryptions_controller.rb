# frozen_string_literal: true

module Api
  module V1
    # POST /api/v1/encryptions/rot13
    #
    # Body: {"original_string": "Hello, world!"}
    class EncryptionsController < Api::BaseController
      MAX_BODY_BYTES = Integer(ENV.fetch('MAX_ENCRYPTION_BYTES', 1_048_576))

      def rot13
        encrypt_with(Ciphers::Rot13::NAME)
      end

      private

      def encrypt_with(cipher_name)
        body = parsed_body
        return render_error(I18n.t('errors.encryption.empty_body'), :unprocessable_entity) if body.nil?

        render_result(
          Encryptions::EncryptStringService.call(original_string: body['original_string'],
                                                 cipher_name: cipher_name)
        )
      end

      # Returns the decoded JSON object, or nil when the body is absent,
      # malformed, or not a JSON object. Returning nil rather than raising keeps
      # a hostile body out of the generic 500 handler.
      def parsed_body
        raw = request.body.read(MAX_BODY_BYTES)
        return nil if raw.blank?

        parsed = JSON.parse(raw)
        parsed.is_a?(Hash) ? parsed : nil
      rescue JSON::ParserError
        nil
      end

      def render_error(message, status)
        render json: { error: message }, status: status
      end
    end
  end
end
