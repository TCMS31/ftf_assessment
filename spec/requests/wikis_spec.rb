# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /wiki' do
  it 'renders the article beside its translation' do
    stub_wikipedia_article('Pig_Latin', paragraphs: ['Hello world'])

    get '/wiki/Pig_Latin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Hello world')
    expect(response.body).to include('Ellohay orldway')
  end

  it 'serves JSON when asked' do
    stub_wikipedia_article('Pig_Latin', paragraphs: ['Hello world', 'Second one'])

    get '/wiki/Pig_Latin.json'

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      'original_content' => "Hello world\n\nSecond one",
      'translated_content' => "Ellohay orldway\n\nEcondsay oneway",
      'error_message' => ''
    )
  end

  it 'accepts the title as a query parameter, for the on-page form' do
    stub_wikipedia_article('Pig_Latin', paragraphs: ['Hello world'])

    get '/wiki', params: { wiki_url: 'Pig Latin' }

    expect(response.body).to include('Ellohay orldway')
  end

  it 'shows the empty state at the root with no article requested' do
    get '/'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Enter an article title above')
  end

  # Regression: a title with a space raised URI::InvalidURIError inside the
  # service; the blanket rescue_from in ApplicationController then rendered a
  # JSON blob containing the internal Wikipedia URL into an HTML page request.
  it 'handles a title that is not URI-safe as HTML, not as a JSON error blob' do
    stub_request(:get, /wikipedia\.org/).to_return(status: 404)

    get '/wiki', params: { wiki_url: "Rock 'n' roll" }

    expect(response.media_type).to eq('text/html')
    expect(response.body).not_to include('en.wikipedia.org')
    expect(response.body).to include('Could not retrieve that Wikipedia article')
  end

  it 'renders an inline error when Wikipedia is unreachable' do
    stub_request(:get, /wikipedia\.org/).to_raise(SocketError)

    get '/wiki/Anything'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Could not retrieve that Wikipedia article')
    expect(response.body).not_to include('SocketError')
  end

  it 'reports a bad gateway on the JSON endpoint when Wikipedia fails' do
    stub_request(:get, /wikipedia\.org/).to_return(status: 500)

    get '/wiki/Anything.json'

    expect(response).to have_http_status(:bad_gateway)
    expect(response.parsed_body['error_message']).to be_present
  end

  it 'escapes article text rather than rendering it as markup' do
    stub_wikipedia_article('Xss', paragraphs: ['<script>alert(1)</script>'])

    get '/wiki/Xss'

    expect(response.body).not_to include('<script>alert(1)</script>')
    expect(response.body).to include('&lt;script&gt;')
  end
end

RSpec.describe 'GET /up' do
  it 'answers without touching the database or the network' do
    get '/up'

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('ok')
  end
end
