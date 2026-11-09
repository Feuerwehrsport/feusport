# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::DocsController do
  it 'shows the documentation built from the OpenAPI file' do
    get '/api/docs'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('PATCH /api/v1/list_entries/{id}', 'time_left_target', 'openapi.yaml')
  end
end
