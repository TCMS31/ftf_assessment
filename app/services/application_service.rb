# frozen_string_literal: true

# Base class for the orchestration layer.
#
# Services coordinate the pure domain objects in `app/lib`, the outbound client
# in `app/clients` and the models. They never touch `params`, `request` or
# `render`; they return a {ServiceResult} and let the controller decide how to
# present it. That is what keeps controllers thin and the domain testable.
class ApplicationService
  # Convenience so callers can write `MyService.call(foo: 1)`.
  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end
end
