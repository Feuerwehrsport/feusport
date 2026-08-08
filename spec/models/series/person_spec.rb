# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::Person do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:config) { round.person_config_for('male-hl') }
  let(:person) do
    described_class.new(
      config:, person: fss_person, round:,
    )
  end
  let(:fss_person) { create(:fire_sport_statistics_person) }
  let!(:person_participation) do
    create(:series_person_participation,
           person_assessment: build(:series_person_assessment, round:),
           cup: build(:series_cup, round:),
           person: fss_person)
  end

  describe 'supports Certificates::StorageSupport' do
    it 'supports all keys' do
      person.rank = 42
      person.add_participation(person_participation)

      {
        team_name: '',
        person_name: 'Alfred Meier',
        person_bib_number: '',
        time_long: '',
        time_short: '',
        time_without_seconds: '',
        rank: '42.',
        rank_with_rank: '42. Platz',
        rank_without_dot: '42',
        assessment: 'D-Cup',
        assessment_with_gender: '',
        result_name: 'HL-Männer',
        date: '',
        place: '',
        competition_name: '',
        points: '15',
        points_with_points: '15 Punkte',
        text: 'foo',
      }.each do |key, value|
        expect(person.storage_support_get(Certificates::TextField.new(key:, text: 'foo')).to_s).to eq value
      end
    end
  end
end
