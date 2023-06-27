# frozen_string_literal: true

require 'erb'
require 'net/http'
require 'nokogiri'

# The only place in the app that talks to the network.
#
# Isolating it here means the translation pipeline can be unit tested without
# stubbing `Net::HTTP`, and swapping the source (the Wikipedia action API, an
# offline mirror, a different wiki) is a one-class change.
class WikipediaClient
  # Raised for every failure mode the caller cares about — DNS, TLS, timeout,
  # non-200 — so callers rescue one class instead of a dozen.
  class FetchError < StandardError; end

  # Network errors that are worth reporting as "could not reach Wikipedia"
  # rather than letting escape as a 500. `Net::HTTP` can raise any of these.
  TRANSPORT_ERRORS = [
    Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
    EOFError, IOError, OpenSSL::SSL::SSLError, SocketError, Timeout::Error,
    Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError
  ].freeze

  DEFAULT_BASE_URL = 'https://en.wikipedia.org/wiki/'
  DEFAULT_OPEN_TIMEOUT = 3
  DEFAULT_READ_TIMEOUT = 5
  USER_AGENT = 'ftf-assessment/1.0 (https://github.com/; pig latin translator)'

  # @param base_url [String]
  # @param open_timeout [Numeric] seconds to wait for the TCP/TLS handshake
  # @param read_timeout [Numeric] seconds to wait for the response body
  def initialize(base_url: ENV.fetch('WIKIPEDIA_BASE_URL', DEFAULT_BASE_URL),
                 open_timeout: ENV.fetch('WIKIPEDIA_OPEN_TIMEOUT', DEFAULT_OPEN_TIMEOUT).to_f,
                 read_timeout: ENV.fetch('WIKIPEDIA_READ_TIMEOUT', DEFAULT_READ_TIMEOUT).to_f)
    @base_url = base_url
    @open_timeout = open_timeout
    @read_timeout = read_timeout
  end

  # Fetches an article and returns its body paragraphs.
  #
  # @param title [String] a Wikipedia article title, e.g. "Pig Latin"
  # @return [Array<String>] non-empty paragraph texts, in document order
  # @raise [FetchError] on any transport failure, bad title or non-200 response
  def article_paragraphs(title)
    paragraphs(fetch(title))
  end

  private

  attr_reader :base_url, :open_timeout, :read_timeout

  def fetch(title)
    uri = article_uri(title)
    response = get(uri)

    raise FetchError, "Wikipedia returned #{response.code} for #{title.inspect}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                        open_timeout: open_timeout, read_timeout: read_timeout) do |http|
      http.request(Net::HTTP::Get.new(uri, 'User-Agent' => USER_AGENT))
    end
  rescue *TRANSPORT_ERRORS => e
    raise FetchError, "Could not reach Wikipedia: #{e.class}"
  end

  # Article titles routinely contain spaces, quotes, parentheses and other
  # characters that are illegal in a raw URI. Escaping the segment is what stops
  # `/wiki/Rock 'n' roll` raising URI::InvalidURIError deep inside the request.
  def article_uri(title)
    URI.parse("#{base_url}#{ERB::Util.url_encode(title.to_s.tr(' ', '_'))}")
  rescue URI::Error
    raise FetchError, "Invalid article title: #{title.inspect}"
  end

  def paragraphs(html)
    Nokogiri::HTML(html).css('p').map { |node| node.text.strip }.reject(&:empty?)
  end
end
