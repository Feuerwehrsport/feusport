# frozen_string_literal: true

class Api::V1::PairingsController < Api::V1::BaseController
  skip_before_action :authenticate_api_access!
  rate_limit to: 10, within: 1.minute, only: :create, with: -> { render_error(:too_many_requests, :too_many_requests) }

  def create
    access = ApiAccess.pair(params[:code], device_name: params[:device_name])
    return render_error(:unauthorized, :invalid_code) if access.nil?

    render json: {
      token: access.token,
      token_expires_at: access.token_expires_at,
      competition: { id: access.competition.id, name: access.competition.name, date: access.competition.date },
    }, status: :created
  end
end
