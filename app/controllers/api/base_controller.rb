# frozen_string_literal: true

module Api
  # Base controller for the JSON API.
  #
  # API clients get a stable `{"error": "..."}` envelope for every failure. The
  # exception detail is logged, never serialised: the old handler echoed
  # `exception.message` straight back, which for a `{"original_string": 123}`
  # body returned the offending line of Ruby source to the caller.
  class BaseController < ActionController::API
    rescue_from StandardError, with: :render_internal_error
    rescue_from ActionController::ParameterMissing, with: :render_bad_request

    private

    # @param result [ServiceResult]
    def render_result(result)
      render json: result.to_h, status: result.status
    end

    def render_bad_request(exception)
      render json: { error: exception.message }, status: :bad_request
    end

    def render_internal_error(exception)
      Rails.logger.error("#{exception.class}: #{exception.message}")
      Rails.logger.error(exception.backtrace&.first(10)&.join("\n"))

      render json: { error: I18n.t('errors.internal') }, status: :internal_server_error
    end
  end
end
