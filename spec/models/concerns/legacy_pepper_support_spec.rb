# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LegacyPepperSupport do
  let(:user) { create(:user) }
  let(:legacy_hash) do
    BCrypt::Password.create("Password#{described_class::LEGACY_PEPPER}", cost: BCrypt::Engine::MIN_COST).to_s
  end

  before { user.update_columns(encrypted_password: legacy_hash) }

  it 'accepts old hashes once and stores a new hash with the current pepper' do
    expect(user.valid_password?('Password')).to be true

    new_hash = user.reload.encrypted_password
    expect(new_hash).not_to eq legacy_hash
    expect(Devise::Encryptor.compare(User, new_hash, 'Password')).to be true
    expect(user.valid_password?('Password')).to be true
  end

  it 'rejects wrong passwords without changing the hash' do
    expect(user.valid_password?('Falsch')).to be false
    expect(user.reload.encrypted_password).to eq legacy_hash
  end

  it 'handles invalid hashes' do
    user.update_columns(encrypted_password: 'kein-bcrypt')
    expect(user.valid_password?('Password')).to be false
  end
end
