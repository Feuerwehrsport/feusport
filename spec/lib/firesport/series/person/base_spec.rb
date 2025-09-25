# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Firesport::Series::Person::Base do
  describe 'supports Certificates::StorageSupport' do
    let(:base) { described_class.new(round, person).tap { |b| b.instance_variable_set(:@rank, 1) } }
    let(:round) { create(:series_round) }
    let(:person) { create(:fire_sport_statistics_person) }

    it 'supports all keys' do
      [
        {
          team_name: '',
          person_name: 'Alfred Meier',
          person_bib_number: '',
          time_long: '',
          time_very_long: '',
          time_other_long: '',
          time_short: '',
          time_without_seconds: '',
          rank: '1.',
          rank_with_rank: '1. Platz',
          rank_with_rank2: 'den 1. Platz',
          rank_without_dot: '1',
          assessment: '',
          assessment_with_gender: '',
          gender: '',
          result_name: 'D-Cup',
          date: '',
          place: '',
          competition_name: '',
          points: '0',
          points_with_points: '0 Punkte',
          text: 'foo',

        },
      ].each_with_index do |row_match, _index|
        row_match.each do |key, value|
          expect(base.storage_support_get(Certificates::TextField.new(key:, text: 'foo')).to_s).to eq value
        end
      end
    end
  end
end
