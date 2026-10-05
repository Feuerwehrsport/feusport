# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::EntitySupport do
  let(:round) { build(:series_round, name: 'D-Cup') }
  let(:config) do
    Series::AssessmentConfig.new(key: 'male-la', name: 'LA-Männer', disciplines: ['la'], calc_participations_count: 2)
  end
  let(:team) { Series::Team.new(config:, round:, team_number: 1) }
  let(:la_assessment) { Series::TeamAssessment.new(discipline: 'la') }
  let(:hl_assessment) { Series::TeamAssessment.new(discipline: 'hl') }

  def participation(cup_id, points:, time:, rank:, assessment: la_assessment)
    Series::TeamParticipation.new(cup_id:, points:, time:, rank:, team_assessment: assessment)
  end

  describe 'participation calculations' do
    before do
      team.add_participation(participation(1, points: 10, time: 2200, rank: 3))
      team.add_participation(participation(2, points: 15, time: Firesport::INVALID_TIME, rank: 1))
      team.add_participation(participation(3, points: 10, time: 2000, rank: 1))
    end

    it 'orders participations by points and time and limits them' do
      expect(team.ordered_participations.map(&:cup_id)).to eq [2, 3]
      expect(team.participation_count).to eq 3
      expect(team.valid_participations.map(&:cup_id)).to eq [3]
    end

    it 'calculates best ranks' do
      expect(team.best_rank).to eq 1
      expect(team.best_rank_count).to eq 2
    end

    it 'returns best time' do
      expect(team.best_time_without_nil).to eq 2000
    end
  end

  describe '#best_time_without_nil' do
    it 'returns a value greater than invalid time if no time is present' do
      team.add_participation(participation(1, points: 10, time: 2000, rank: 1, assessment: hl_assessment))
      expect(team.best_time_without_nil).to eq Firesport::INVALID_TIME + 1
    end
  end

  describe '#storage_support_get' do
    def get(key)
      team.storage_support_get(Certificates::TextField.new(key:, text: 'foo'))
    end

    it 'returns rank keys as strings' do
      team.rank = 4
      expect(get(:rank)).to eq '4.'
      expect(get(:rank_with_rank)).to eq '4. Platz'
      expect(get(:rank_with_rank2)).to eq 'den 4. Platz'
      expect(get(:rank_without_dot)).to eq '4'
    end
  end
end
