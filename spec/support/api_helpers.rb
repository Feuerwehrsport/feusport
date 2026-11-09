# frozen_string_literal: true

module ApiHelpers
  include Committee::Rails::Test::Methods

  def committee_options
    @committee_options ||= { schema_path: Rails.public_path.join('api/v1/openapi.yaml').to_s,
                             strict_reference_validation: true }
  end

  def api_headers(access)
    access.pair(nil)
    { 'Authorization' => "Bearer #{access.token}" }
  end

  def json
    response.parsed_body
  end

  def expect_documented(status)
    expect(response).to have_http_status(status)
    assert_response_schema_confirm(status)
  end
end

RSpec.configure { |config| config.include ApiHelpers, type: :request }
