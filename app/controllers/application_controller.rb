# frozen_string_literal: true

# Base controller for the HTML side of the app.
#
# Deliberately does NOT install a blanket `rescue_from StandardError`. The
# previous version did, and it rendered a JSON body containing the raw exception
# message — including source excerpts — in response to HTML page requests. Rails'
# own exception handling already renders the right thing for the right format,
# and `config.consider_all_requests_local` controls how much detail is shown.
class ApplicationController < ActionController::Base
end
