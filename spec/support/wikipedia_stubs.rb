# frozen_string_literal: true

# Helpers for driving WikipediaClient against fixed HTML instead of the network.
module WikipediaStubs
  def stub_wikipedia_article(title, paragraphs:, status: 200)
    body = paragraphs.map { |text| "<p>#{ERB::Util.html_escape(text)}</p>" }.join
    stub_request(:get, "https://en.wikipedia.org/wiki/#{ERB::Util.url_encode(title)}")
      .to_return(status: status, body: "<html><body><div id=\"mw-content-text\">#{body}</div></body></html>")
  end

  def stub_wikipedia_missing(title)
    stub_request(:get, "https://en.wikipedia.org/wiki/#{ERB::Util.url_encode(title)}")
      .to_return(status: 404, body: '<html><body><p>Not found</p></body></html>')
  end
end

RSpec.configure do |config|
  config.include WikipediaStubs
end
