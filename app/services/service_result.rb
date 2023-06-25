# frozen_string_literal: true

# The value every service returns.
#
# It replaces the previous `[payload_hash, { status: :ok }]` array, which forced
# callers to index into positions (`resp[0]`, `resp[1][:status]`) and made the
# success/failure branch invisible at the call site.
class ServiceResult
  attr_reader :data, :error, :status

  # @param data [Hash] the successful payload
  # @param status [Symbol] Rack status symbol for HTTP callers
  def self.success(data = {}, status: :ok)
    new(success: true, data: data, status: status)
  end

  # @param error [String] a message safe to show to an end user
  def self.failure(error, data = {}, status: :unprocessable_entity)
    new(success: false, data: data, error: error, status: status)
  end

  def initialize(success:, data: {}, error: nil, status: :ok)
    @success = success
    @data = data.freeze
    @error = error
    @status = status
    freeze
  end

  def success? = @success
  def failure? = !@success

  # Body shape shared by the JSON API and the HTML views.
  def to_h = data.merge(error: error)
end
