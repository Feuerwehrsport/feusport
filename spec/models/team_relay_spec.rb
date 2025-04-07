# frozen_string_literal: true

# == Schema Information
#
# Table name: team_relays
#
#  id         :uuid             not null, primary key
#  number     :integer          default(1), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :uuid             not null
#
# Indexes
#
#  index_team_relays_on_team_id  (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
require 'rails_helper'

RSpec.describe TeamRelay do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:team) { create(:team, competition:, band:) }

  describe '#name' do
    let(:team_relay) { described_class.new(team:) }

    it 'replaces numbers with letters' do
      expect(team_relay.name).to eq 'A'
    end
  end

  describe '.create_next_free' do
    let!(:team_relay_a) { described_class.create!(team:) }

    it 'creates new team_relays for team' do
      # team A already exists
      expect(team_relay_a.name).to eq 'A'

      team_relay_b = described_class.create_next_free(team)
      expect(team_relay_b).to be_a(described_class)
      expect(team_relay_b.name).to eq 'B'

      team_relay_c = described_class.create_next_free(team)
      expect(team_relay_c).to be_a(described_class)
      expect(team_relay_c.name).to eq 'C'
    end
  end

  describe '.create_next_free_for' do
    let!(:team_relay_a) { described_class.create!(team:) }

    context 'when no ids are set before' do
      it 'returns existing relay' do
        team_relay = described_class.create_next_free_for(team, [])
        expect(team_relay).to eq team_relay_a
      end
    end

    context 'when used ids are set before' do
      it 'returns creates new relay' do
        team_relay = described_class.create_next_free_for(team, [team_relay_a.id])
        expect(team_relay).not_to eq team_relay_a
        expect(team_relay).to be_a(described_class)
        expect(team_relay.name).to eq 'B'
      end
    end
  end
end
