# frozen_string_literal: true

class Api::DocsController < ApplicationController
  OPENAPI_PATH = Rails.public_path.join('api/v1/openapi.yaml')

  def show
    @openapi = YAML.safe_load_file(OPENAPI_PATH)
  end
end
