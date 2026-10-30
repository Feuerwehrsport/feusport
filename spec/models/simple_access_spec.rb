# frozen_string_literal: true

require 'rails_helper'

# == Schema Information
#
# Table name: simple_accesses
#
#  id              :uuid             not null, primary key
#  name            :string           not null
#  password_digest :string
#  permission      :integer          default(0), not null
#  score_list_ids  :uuid             default([]), not null, is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  competition_id  :uuid             not null
#
# Indexes
#
#  index_simple_accesses_on_competition_id           (competition_id)
#  index_simple_accesses_on_competition_id_and_name  (competition_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
RSpec.describe SimpleAccess do
  let(:competition) { create(:competition) }

  describe 'name' do
    it 'is free text, unique per competition and limited to 50 characters' do
      described_class.create!(competition:, name: 'Zeitnehmer Löschangriff', password: 'lang1234')

      access = described_class.new(competition:, name: 'Zeitnehmer Löschangriff', password: 'lang1234')
      expect(access).not_to be_valid
      expect(access.errors.details[:name]).to include(a_hash_including(error: :taken))

      access.name = 'x' * 51
      expect(access).not_to be_valid
      expect(access.errors.details[:name]).to include(a_hash_including(error: :too_long))

      access.name = 'Zeitnehmer Hakenleitersteigen'
      expect(access).to be_valid
    end
  end

  describe 'password' do
    it 'requires at least 8 characters for new passwords' do
      access = described_class.new(competition:, name: 'Admin', password: 'kurz123')
      expect(access).not_to be_valid
      expect(access.errors.details[:password]).to include(a_hash_including(error: :too_short))

      access.password = 'lang1234'
      expect(access).to be_valid
    end

    it 'keeps existing short passwords valid' do
      access = described_class.new(competition:, name: 'Admin', password: 'kurz')
      access.save!(validate: false)

      expect(described_class.find(access.id)).to be_valid
    end
  end
end
