# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_api_access!

  rescue_from(ActiveRecord::RecordNotFound) { render_error(:not_found, :not_found) }
  rescue_from(ActionDispatch::Http::Parameters::ParseError) { render_error(:bad_request, :invalid_json) }

  private

  attr_reader :current_api_access

  def authenticate_api_access!
    @current_api_access = authenticate_with_http_token { |token, _options| ApiAccess.authenticate(token) }
    return render_error(:unauthorized, :invalid_token) if @current_api_access.nil?

    @current_api_access.record_usage
  end

  def accessible_lists
    current_api_access.competition.score_lists.accessible_by(Ability.new(nil, api_access: current_api_access),
                                                             :edit_times)
  end

  def render_error(status, code, **details)
    render json: { error: code, **details }, status:
  end
end
