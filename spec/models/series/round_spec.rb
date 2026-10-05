# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::Round do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }

  describe 'validation of assessment configs' do
    it 'is valid with correct configs' do
      expect(round).to be_valid
    end

    it 'adds errors for invalid config entries' do
      round.team_assessments_config_jsonb = [{ 'key' => 'male-la' }]
      expect(round).not_to be_valid
      expect(round.errors[:team_assessments_config_jsonb]).to include(match(/\AEintrag 0: /))
      expect(round.errors[:team_assessments_config_jsonb_text]).to include(match(/\AEintrag 0: /))
    end

    it 'adds errors if config is not an array' do
      round.person_assessments_config_jsonb = { 'key' => 'male-hl' }
      expect(round.person_assessments_configs).to eq []
      expect(round.errors.details[:person_assessments_config_jsonb]).to include(error: :invalid)
      expect(round.errors.details[:person_assessments_config_jsonb_text]).to include(error: :invalid)
    end

    it 'adds errors if config entry is not a hash' do
      round.team_assessments_config_jsonb = ['foo']
      expect(round.team_assessments_configs).to eq []
      expect(round.errors.details[:team_assessments_config_jsonb]).to include(error: :invalid)
      expect(round.errors.details[:team_assessments_config_jsonb_text]).to include(error: :invalid)
    end
  end

  describe '.possible_series_round_keys' do
    let!(:old_round) do
      create(:series_round, :with_team_config, :with_person_config, name: 'A-Cup', year: Date.current.year - 1)
    end

    before { round }

    it 'returns keys of current rounds' do
      expect(described_class.possible_series_round_keys(:team)).to eq [
        ["D-Cup - #{round.year} - LA-Männer", "#{round.id}-male-la"],
      ]
    end

    it 'filters by discipline' do
      expect(described_class.possible_series_round_keys(:team, discipline_key: 'hl')).to eq []
      expect(described_class.possible_series_round_keys(:person, discipline_key: 'hl')).to eq [
        ["D-Cup - #{round.year} - HL-Männer", "#{round.id}-male-hl"],
      ]
    end

    it 'includes given round keys of older rounds' do
      expect(described_class.possible_series_round_keys(:team, with_round_keys: ["#{old_round.id}-male-la"])).to eq [
        ["A-Cup - #{old_round.year} - LA-Männer", "#{old_round.id}-male-la"],
        ["D-Cup - #{round.year} - LA-Männer", "#{round.id}-male-la"],
      ]
    end
  end

  describe '#disciplines' do
    it 'returns all disciplines of all configs' do
      expect(round.disciplines).to eq %w[hl la]
    end
  end

  describe '#round' do
    it 'returns itself' do
      expect(round.round).to be round
    end
  end

  describe 'counts' do
    let(:cup) { create(:series_cup, round:) }
    let(:team_assessment) { create(:series_team_assessment, round:) }
    let(:person_assessment) { create(:series_person_assessment, round:) }
    let(:fss_team) { create(:fire_sport_statistics_team) }
    let(:fss_person) { create(:fire_sport_statistics_person) }

    it 'counts unique teams and people' do
      create(:series_team_participation, cup:, team_assessment:, team: fss_team, team_number: 1, team_gender: 1)
      create(:series_team_participation, cup:, team_assessment:, team: fss_team, team_number: 1, team_gender: 1)
      create(:series_team_participation, cup:, team_assessment:, team: fss_team, team_number: 2, team_gender: 1)
      create(:series_person_participation, cup:, person_assessment:, person: fss_person)
      create(:series_person_participation, cup:, person_assessment:, person: fss_person)

      expect(round.team_count).to eq 2
      expect(round.person_count).to eq 1
    end

    it 'calculates cups and completeness' do
      round.update!(full_cup_count: 2)
      expect(round.cup_count).to eq 0
      expect(round.cups_left).to eq 2
      expect(round).not_to be_complete

      create(:series_cup, round:)
      create(:series_cup, round:)
      round.reload
      expect(round.cup_count).to eq 2
      expect(round.cups_left).to eq 0
      expect(round).to be_complete
    end

    it 'uses preloaded cup_count attribute' do
      loaded = described_class.select('series_rounds.*, 3 AS cup_count').find(round.id)
      expect(loaded.cup_count).to eq 3
      expect(loaded.cups_left).to eq 1
    end
  end
end
