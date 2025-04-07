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
#  applicant_id                    :uuid
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
#  fk_rails_...  (applicant_id => users.id)
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
end
