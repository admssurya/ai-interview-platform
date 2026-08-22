# frozen_string_literal: true

# spec/support/json_helpers.rb
module JsonHelpers
  def json_body
    JSON.parse(response.body)
  end

  def expect_json_response(status: :ok)
    expect(response).to have_http_status(status)
    expect(response.content_type).to include('application/json')
  end

  def expect_error(status:, message: nil)
    expect(response).to have_http_status(status)
    expect(json_body).to have_key('errors')
    expect(json_body['errors'].first['message']).to include(message) if message
  end
end

RSpec.configure do |config|
  config.include JsonHelpers, type: :request
end