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
      format.html { render :translate, status: html_status(result) }
      format.json { render json: json_response, status: result.status }
    end
  end

  private

  # The empty form is a normal page, not an error, so a blank title stays 200.
  # A failed fetch keeps the service's status (502), so the inline error page
  # is not reported to caches and monitors as a success.
  def html_status(result)
    @article_title.blank? ? :ok : result.status
  end

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
