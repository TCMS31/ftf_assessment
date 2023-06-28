# frozen_string_literal: true

# GET /wiki/:wiki_url      — translate a named article
# GET /wiki?wiki_url=Title — same action, reached from the on-page form
class WikisController < ApplicationController
  def translate
    @article_title = wiki_params[:wiki_url].to_s
    result = Translations::PigLatinService.call(article_title: @article_title)

    @original_paragraphs = result.data[:original_paragraphs]
    @translated_paragraphs = result.data[:translated_paragraphs]
    @error_message = result.error

    respond_to do |format|
      format.html { render :translate }
      format.json { render json: json_response, status: result.status }
    end
  end

  private

  def wiki_params
    params.permit(:wiki_url, :format)
  end

  def json_response
    { original_content: @original_paragraphs.join("\n\n"),
      translated_content: @translated_paragraphs.join("\n\n"),
      original_paragraphs: @original_paragraphs,
      translated_paragraphs: @translated_paragraphs,
      error_message: @error_message.to_s }
  end
end
