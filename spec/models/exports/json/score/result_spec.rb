# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Json::Score::Result do
  let(:competition) { create(:competition) }
  let!(:fs) { create(:discipline, :fs, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment) { create(:assessment, competition:, discipline: fs, band: female) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:team) { create(:team, competition:, band: female, number: 1) }
  let(:relay_a) { TeamRelay.create!(team:, number: 1) }
  let(:relay_b) { TeamRelay.create!(team:, number: 2) }

  it 'exports the team number for relays' do
    create_score_list(result, relay_a => 2000, relay_b => 2100)

    rows = described_class.new(result).to_hash[:rows]
    expect(rows.first).to include('statistik_team_number')
    number_index = rows.first.index('statistik_team_number')
    expect(rows.drop(1).map { |row| [row[1], row[number_index]] }).to eq [
      ["#{team.full_name} A", 1],
      ["#{team.full_name} B", 1],
    ]
  end
end
