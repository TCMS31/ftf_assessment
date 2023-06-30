# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikipediaClient do
  subject(:client) { described_class.new }

  describe '#article_paragraphs' do
    it 'returns the article paragraphs in document order' do
      stub_wikipedia_article('Pig_Latin', paragraphs: ['First para.', 'Second para.'])

      expect(client.article_paragraphs('Pig_Latin')).to eq(['First para.', 'Second para.'])
    end

    it 'drops blank paragraphs and trims whitespace' do
      stub_request(:get, 'https://en.wikipedia.org/wiki/Test')
        .to_return(status: 200, body: '<html><body><p>  Kept  </p><p> </p><p></p></body></html>')

      expect(client.article_paragraphs('Test')).to eq(['Kept'])
    end

    # Regression: titles containing a space, a caret or an apostrophe used to
    # raise URI::InvalidURIError, which escaped the service and was rendered to
    # the user as a raw JSON exception message on an HTML page request.
    it 'escapes titles that are not URI-safe' do
      stub_request(:get, 'https://en.wikipedia.org/wiki/Rock_%27n%27_roll').to_return(status: 200, body: '<p>ok</p>')

      expect { client.article_paragraphs("Rock 'n' roll") }.not_to raise_error
    end

    it 'converts spaces in a title to underscores' do
      stub = stub_wikipedia_article('Pig_Latin', paragraphs: ['ok'])
      client.article_paragraphs('Pig Latin')

      expect(stub).to have_been_requested
    end

    it 'sends a descriptive User-Agent' do
      stub = stub_request(:get, 'https://en.wikipedia.org/wiki/Test')
             .with(headers: { 'User-Agent' => described_class::USER_AGENT })
             .to_return(status: 200, body: '<p>ok</p>')
      client.article_paragraphs('Test')

      expect(stub).to have_been_requested
    end

    it 'raises FetchError on a 404' do
      stub_wikipedia_missing('Nope')

      expect { client.article_paragraphs('Nope') }
        .to raise_error(described_class::FetchError, /404/)
    end

    it 'raises FetchError on a 500' do
      stub_request(:get, 'https://en.wikipedia.org/wiki/Test').to_return(status: 500)

      expect { client.article_paragraphs('Test') }.to raise_error(described_class::FetchError, /500/)
    end

    # The original rescue listed only Net::HTTPError, Net::ReadTimeout and
    # Net::OpenTimeout, so DNS, TLS and connection-refused failures escaped.
    [SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, Net::OpenTimeout, Net::ReadTimeout].each do |error|
      it "converts #{error} into a FetchError" do
        stub_request(:get, 'https://en.wikipedia.org/wiki/Test').to_raise(error)

        expect { client.article_paragraphs('Test') }
          .to raise_error(described_class::FetchError, /Could not reach Wikipedia/)
      end
    end

    it 'does not leak the exception message to the caller' do
      stub_request(:get,
                   'https://en.wikipedia.org/wiki/Test').to_raise(SocketError.new('getaddrinfo: nodename nor servname'))

      expect { client.article_paragraphs('Test') }.to raise_error(described_class::FetchError) { |e|
        expect(e.message).not_to include('getaddrinfo')
      }
    end
  end

  describe 'timeouts' do
    it 'defaults to short open and read timeouts' do
      expect(described_class::DEFAULT_OPEN_TIMEOUT).to be <= 5
      expect(described_class::DEFAULT_READ_TIMEOUT).to be <= 10
    end

    it 'reads the timeouts from the environment' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('WIKIPEDIA_OPEN_TIMEOUT', anything).and_return('1.5')

      expect(described_class.new.send(:open_timeout)).to eq(1.5)
    end
  end
end
