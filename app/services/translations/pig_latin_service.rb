# frozen_string_literal: true

require 'digest'

module Translations
  # Fetches a Wikipedia article and returns it alongside its Pig Latin translation.
  #
  # Fetch and translate are both expensive and both perfectly deterministic for a
  # given title, so the successful pair is memoised in `Rails.cache`. A repeat
  # request for the same article skips the round trip to Wikipedia and the
  # per-word translation entirely.
  class PigLatinService < ApplicationService
    CACHE_NAMESPACE = 'pig_latin/article'
    DEFAULT_CACHE_TTL_SECONDS = 3600
    EMPTY_ARTICLE = { original_paragraphs: [], translated_paragraphs: [] }.freeze

    # @param article_title [String] e.g. "Pig Latin" or "Pig_Latin"
    # @param client [#article_paragraphs] injected for tests and for swapping the source
    # @param cache_ttl [ActiveSupport::Duration, Integer]
    def initialize(article_title:, client: WikipediaClient.new, cache_ttl: self.class.cache_ttl)
      @article_title = normalize(article_title)
      @client = client
      @cache_ttl = cache_ttl
      super()
    end

    # @return [ActiveSupport::Duration]
    def self.cache_ttl
      Integer(ENV.fetch('WIKIPEDIA_CACHE_TTL_SECONDS', DEFAULT_CACHE_TTL_SECONDS)).seconds
    end

    # @return [ServiceResult] data is {original_paragraphs:, translated_paragraphs:}
    def call
      return blank_title_failure if article_title.blank?

      ServiceResult.new(**Rails.cache.fetch(cache_key, expires_in: cache_ttl) { translate })
    rescue WikipediaClient::FetchError => e
      # The detail goes to the log; the caller gets a message that leaks nothing
      # about our URLs or exception classes.
      Rails.logger.info("PigLatinService: #{e.message}")
      ServiceResult.failure(I18n.t('errors.translation.fetch_failed'), EMPTY_ARTICLE, status: :bad_gateway)
    end

    private

    attr_reader :article_title, :client, :cache_ttl

    def normalize(title) = title.to_s.strip.tr(' ', '_')

    # Only successful fetches reach the cache: `Rails.cache.fetch` stores the
    # block's value, and a failed fetch raises out of the block instead.
    def translate
      original = client.article_paragraphs(article_title)
      translated = original.map { |paragraph| PigLatin::Translator.translate(paragraph) }

      { success: true, status: :ok,
        data: { original_paragraphs: original, translated_paragraphs: translated } }
    end

    # Titles can be arbitrarily long and contain characters a cache backend may
    # not accept, so the key is a digest rather than the title itself.
    def cache_key = "#{CACHE_NAMESPACE}/#{Digest::SHA256.hexdigest(article_title)}"

    def blank_title_failure
      ServiceResult.failure(I18n.t('errors.translation.blank_title'), EMPTY_ARTICLE)
    end
  end
end
