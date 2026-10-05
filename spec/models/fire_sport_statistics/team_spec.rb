# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_teams
#
#  id          :bigint           not null, primary key
#  best_scores :jsonb
#  dummy       :boolean          default(FALSE), not null
#  name        :string(100)      not null
#  short       :string(50)       not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe FireSportStatistics::Team do
  describe '#team_best_table' do
    let(:team) do
      build(:fire_sport_statistics_team, best_scores: {
              'female' => {
                'din' => { 'pb' => [2234, 'Wettkampf A'], 'sb' => [2345, 'Wettkampf B'] },
                'tgl' => { 'sb' => [3456, 'Wettkampf C'] },
              },
              'male' => { 'tgl' => { 'pb' => [1999, 'Wettkampf D'] } },
            })
    end

    it 'returns table for available entries' do
      expect(team.team_best_table('female')).to eq(
        'din' => {
          ['PB', 'Persönliche Bestleistung'] => ['22,34', 'Wettkampf A'],
          %w[SB Saison-Bestleistung] => ['23,45', 'Wettkampf B'],
        },
        'tgl' => {
          %w[SB Saison-Bestleistung] => ['34,56', 'Wettkampf C'],
        },
      )
      expect(team.team_best_table('male')).to eq(
        'tgl' => { ['PB', 'Persönliche Bestleistung'] => ['19,99', 'Wettkampf D'] },
      )
    end

    it 'returns nil for missing gender' do
      expect(team.team_best_table('indifferent')).to be_nil
    end
  end
end
