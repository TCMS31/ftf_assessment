# frozen_string_literal: true

Rails.application.routes.draw do
  root 'wikis#translate'

  # Liveness probe for the container healthcheck and any load balancer in front
  # of it. Cheap on purpose: no database, no network.
  get '/up', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }

  namespace :api do
    namespace :v1 do
      resources :encryptions, only: [] do
        collection do
          post :rot13
        end
      end
    end
  end

  # Two entry points into the same action: a clean permalink for an article and
  # a query-string form target, so the page can offer a search box.
  get '/wiki', to: 'wikis#translate', as: :wiki_search
  get '/wiki/:wiki_url', to: 'wikis#translate', as: :wiki_translate
end
