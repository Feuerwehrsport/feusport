# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  it 'connects without identification' do
    connect '/cable'
    expect(connection.current_user).to be_nil
  end

  it 'treats timed out sessions as anonymous' do
    warden = instance_double(Warden::Proxy)
    allow(warden).to receive(:user) { throw :warden, scope: :user, message: :timeout }

    connect '/cable', env: { 'warden' => warden }
    expect(connection.current_user).to be_nil
  end

  it 'identifies the user from warden' do
    user = create(:user)
    connect '/cable', env: { 'warden' => instance_double(Warden::Proxy, user:) }
    expect(connection.current_user).to eq user
  end
end
