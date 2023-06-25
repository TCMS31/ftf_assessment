# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Translations::PigLatinService do
  describe '#call' do
    it 'returns the article and its translation, paragraph by paragraph' do
      stub_wikipedia_article('Pig_Latin', paragraphs: ['Hello world', 'Second one'])

      result = described_class.call(article_title: 'Pig Latin')

      expect(result).to be_success
      expect(result.data[:original_paragraphs]).to eq(['Hello world', 'Second one'])
      expect(result.data[:translated_paragraphs]).to eq(['Ellohay orldway', 'Econdsay oneway'])
    end

    it 'fails with a usable message when the article does not exist' do
      stub_wikipedia_missing('Nope')

      result = described_class.call(article_title: 'Nope')

      expect(result).to be_failure
      expect(result.status).to eq(:bad_gateway)
      expect(result.error).to eq('Could not retrieve that Wikipedia article. Check the title and try again.')
      expect(result.data[:original_paragraphs]).to eq([])
    end

    it 'never puts an exception message in the user-facing error' do
      stub_request(:get, /wikipedia\.org/).to_raise(SocketError.new('getaddrinfo failed'))

      expect(described_class.call(article_title: 'Nope').error).not_to include('getaddrinfo')
    end

    it 'fails when no title is given' do
      result = described_class.call(article_title: '')

      expect(result).to be_failure
      expect(result.error).to eq('Please provide a Wikipedia article title')
    end

    it 'treats a whitespace-only title as blank' do
      expect(described_class.call(article_title: "  \t ")).to be_failure
    end
  end

  describe 'caching' do
    it 'fetches an article once and serves repeats from the cache' do
      stub = stub_wikipedia_article('Pig_Latin', paragraphs: ['Hello world'])

      3.times { described_class.call(article_title: 'Pig Latin') }

      expect(stub).to have_been_requested.once
    end

    it 'treats "Pig Latin" and "Pig_Latin" as the same cache entry' do
      stub = stub_wikipedia_article('Pig_Latin', paragraphs: ['Hello world'])

      described_class.call(article_title: 'Pig Latin')
      described_class.call(article_title: 'Pig_Latin')

      expect(stub).to have_been_requested.once
    end

    it 'keys different articles separately' do
      first = stub_wikipedia_article('One', paragraphs: ['a'])
      second = stub_wikipedia_article('Two', paragraphs: ['b'])

      described_class.call(article_title: 'One')
      described_class.call(article_title: 'Two')

      expect(first).to have_been_requested.once
      expect(second).to have_been_requested.once
    end

    # A transient outage must not pin an error page in the cache for an hour.
    it 'does not cache failures' do
      stub_request(:get, 'https://en.wikipedia.org/wiki/Flaky').to_return(status: 500).times(1).then
                                                               .to_return(status: 200, body: '<p>Hello world</p>')

      expect(described_class.call(article_title: 'Flaky')).to be_failure
      expect(described_class.call(article_title: 'Flaky')).to be_success
    end

    it 'honours an injected client, so the source can be swapped' do
      fake = instance_double(WikipediaClient, article_paragraphs: ['Hello world'])

      result = described_class.call(article_title: 'Anything', client: fake)

      expect(result.data[:translated_paragraphs]).to eq(['Ellohay orldway'])
    end
  end
end
