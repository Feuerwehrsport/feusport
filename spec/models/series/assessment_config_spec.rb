# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::AssessmentConfig do
  let(:config) { described_class.new(key: 'test', name: 'Test', disciplines: ['la'], calc_participations_count: 1) }

  def entity(**attributes)
    instance_double(Series::Team, **attributes)
  end

  describe '#sort' do
    {
      'rank' => [{ rank: 1 }, { rank: 2 }],
      'participation_count' => [{ ordered_participations: [1, 2] }, { ordered_participations: [1] }],
      'valid_participation_count' => [{ valid_participations: [1, 2] }, { valid_participations: [1] }],
      'points' => [{ points: 20 }, { points: 10 }],
      'points_reverse' => [{ points: 10 }, { points: 20 }],
      'all_points' => [{ all_points: 20 }, { all_points: 10 }],
      'best_time' => [{ best_time_without_nil: 1900 }, { best_time_without_nil: 2000 }],
      'sum_time' => [{ sum_time: 3900 }, { sum_time: 4000 }],
      'best_rank' => [{ best_rank: 1 }, { best_rank: 3 }],
      'best_rank_count' => [{ best_rank_count: 3 }, { best_rank_count: 1 }],
    }.each do |logic, (better, worse)|
      it "sorts by #{logic}" do
        e1 = entity(**better)
        e2 = entity(**worse)
        expect(config.sort(e1, e2, logic_array: [logic])).to eq(-1)
        expect(config.sort(e2, e1, logic_array: [logic])).to eq 1
        expect(config.sort(e1, e1, logic_array: [logic])).to eq 0
      end
    end

    it 'sorts entities without rank at the end' do
      expect(config.sort(entity(rank: nil), entity(rank: 5), logic_array: ['rank'])).to eq 1
    end

    it 'uses rank first with with_rank' do
      e1 = entity(rank: 1, points: 10)
      e2 = entity(rank: 2, points: 20)
      expect(config.sort(e1, e2, logic_array: ['points'])).to eq 1
      expect(config.sort(e1, e2, logic_array: ['points'], with_rank: true)).to eq(-1)
    end

    it 'uses next logic if first is equal' do
      e1 = entity(points: 10, best_time_without_nil: 1900)
      e2 = entity(points: 10, best_time_without_nil: 2000)
      expect(config.sort(e1, e2, logic_array: %w[points best_time])).to eq(-1)
    end
  end
end
