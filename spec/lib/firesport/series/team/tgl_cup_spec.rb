# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Firesport::Series::Team::TglCup do
  describe '#points_for_result' do
    let(:round) { Series::Round.new(year: 2024) }

    it 'calculates points for result' do
      expect(described_class.points_for_result(1, nil, round, gender: 'male')).to eq 11
      expect(described_class.points_for_result(2, nil, round, gender: 'male')).to eq 10
      expect(described_class.points_for_result(3, nil, round, gender: 'male')).to eq 9
      expect(described_class.points_for_result(4, nil, round, gender: 'male')).to eq 8
      expect(described_class.points_for_result(5, nil, round, gender: 'male')).to eq 7
      expect(described_class.points_for_result(6, nil, round, gender: 'male')).to eq 6
      expect(described_class.points_for_result(7, nil, round, gender: 'male')).to eq 5
      expect(described_class.points_for_result(8, nil, round, gender: 'male')).to eq 4
      expect(described_class.points_for_result(9, nil, round, gender: 'male')).to eq 3
      expect(described_class.points_for_result(10, nil, round, gender: 'male')).to eq 2
      expect(described_class.points_for_result(11, nil, round, gender: 'male')).to eq 1
      expect(described_class.points_for_result(12, nil, round, gender: 'male')).to eq 0
      expect(described_class.points_for_result(13, nil, round, gender: 'male')).to eq 0

      expect(described_class.points_for_result(1, nil, round, gender: 'female')).to eq 1
      expect(described_class.points_for_result(2, nil, round, gender: 'female')).to eq 0
    end
  end

  describe 'compare' do
    it 'sorts' do
      h = {
        a: [[11, 1000], [11, 1000], [10, 1000]],
        b: [[7, 1000], [8, 900], [10, 1000]],
        c: [[8, 1000], [9, 800], [9, 1000]],
        d: [[10, 1000], [10, 700], [10, 1000]],
      }
      expect(generate_series_team_participations(h).sort.map(&:team)).to eq %i[a d c b]
    end
  end
end
