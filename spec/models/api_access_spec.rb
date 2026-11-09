# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiAccess do
  let(:competition) { create(:competition, date: Date.current) }
  let(:access) { described_class.create!(competition:, name: 'Uhr') }

  it 'creates an eight digit code' do
    expect(access.pairing_code).to match(/\A\d{8}\z/)
    expect(access).to be_pairing_code_valid
    expect(access).not_to be_paired
  end

  it 'stores only the digest of the token' do
    access.pair('Gerät')
    expect(access.token_digest).not_to include(access.token)
    expect(described_class.authenticate(access.token)).to eq access
  end

  it 'replaces the token when pairing again' do
    access.pair(nil)
    old_token = access.token
    access.pair(nil)
    expect(described_class.authenticate(old_token)).to be_nil
  end

  it 'can be paired when the selected lists were deleted' do
    list = create(:score_list, competition:)
    access.update!(permission: :selected_results, score_list_ids: [list.id])
    access.update_column(:score_list_ids, [])
    code = access.pairing_code
    expect(described_class.pair(code)).to eq access
    expect(access.score_lists).to be_empty
  end
end
