# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminController do
  include Devise::Test::ControllerHelpers

  controller do
    def index
      render plain: 'admin area'
    end
  end

  let(:user) { create(:user) }

  before { request.host = 'www.example.com' }

  it 'allows access for admin users' do
    user.update!(admin: true)
    sign_in user
    get :index
    expect(response).to have_http_status(:success)
    expect(response.body).to eq 'admin area'
  end

  it 'denies access for other users' do
    sign_in user
    get :index
    expect(response).to redirect_to('/')
    expect(flash[:alert]).to eq 'Zugriff verweigert'
  end
end
