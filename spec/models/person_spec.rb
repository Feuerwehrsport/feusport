# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id                              :uuid             not null, primary key
#  bib_number                      :string(50)
#  first_name                      :string(100)      not null
#  last_name                       :string(100)      not null
#  registration_hint               :text
#  registration_order              :integer          default(0), not null
#  tags                            :string           default([]), is an Array
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  band_id                         :uuid             not null
#  competition_id                  :uuid
#  fire_sport_statistics_person_id :integer
#  team_id                         :uuid
#
# Indexes
#
#  index_people_on_band_id                          (band_id)
#  index_people_on_competition_id                   (competition_id)
#  index_people_on_fire_sport_statistics_person_id  (fire_sport_statistics_person_id)
#  index_people_on_team_id                          (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (band_id => bands.id)
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (team_id => teams.id)
#
require 'rails_helper'

RSpec.describe Person do
  let(:competition) { create(:competition) }
  let(:female) { create(:band, :female, competition:) }
  let(:male) { create(:band, :male, competition:) }

  describe 'validation' do
    let(:team_male) { build_stubbed(:team, competition:, band: male) }
    let(:team_female) { build_stubbed(:team, competition:, band: female) }

    context 'when team band is not person band' do
      let(:person) { build(:person, competition:, team: team_female, band: male) }

      it 'fails on validation' do
        expect(person).not_to be_valid
        expect(person.errors.attribute_names).to include(:team)
      end
    end

    context 'when team band is person band' do
      let(:person) { build(:person, competition:, team: team_male, band: male) }

      it 'fails on validation' do
        expect(person).to be_valid
      end
    end
  end

  describe 'band limit validation' do
    let!(:existing) { create(:person, competition:, band: female) }

    before do
      female.update!(max_people: 1)
      male.update!(max_people: 1)
    end

    it 'only checks when requested' do
      person = build(:person, competition:, band: female)
      expect(person).to be_valid

      person.check_band_limit = true
      expect(person).not_to be_valid
      expect(person.errors.details[:band]).to include(error: :people_limit_reached)
    end

    it 'checks persisted people only on band change' do
      existing.check_band_limit = true
      expect(existing).to be_valid

      create(:person, competition:, band: male)
      existing.band = male
      expect(existing).not_to be_valid
    end
  end

  describe '#<=>' do
    it 'sorts by full name and then by id' do
      person_b = create(:person, competition:, band: male, first_name: 'Bernd')
      person_a1 = create(:person, competition:, band: male, first_name: 'Anna')
      person_a2 = create(:person, competition:, band: male, first_name: 'Anna')

      expect(person_a1 <=> person_b).to eq(-1)
      expect(person_b <=> person_a1).to eq 1
      expect(person_a1 <=> person_a2).to eq(person_a1.id <=> person_a2.id)
      expect(person_a1 <=> person_a2).not_to eq 0
    end
  end

  describe '#export_gender' do
    it 'returns gender of band' do
      expect(build(:person, competition:, band: female).export_gender).to eq 'female'
      expect(described_class.new.export_gender).to be_nil
    end
  end
end
