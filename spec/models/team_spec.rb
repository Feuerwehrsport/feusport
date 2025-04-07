# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :uuid             not null, primary key
#  certificate_name              :string
#  enrolled                      :boolean          default(FALSE), not null
#  lottery_number                :integer
#  name                          :string(100)      not null
#  number                        :integer          default(1), not null
#  registration_hint             :text
#  shortcut                      :string(50)       default(""), not null
#  tags                          :string           default([]), is an Array
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  applicant_id                  :uuid
#  band_id                       :uuid             not null
#  competition_id                :uuid             not null
#  fire_sport_statistics_team_id :integer
#
# Indexes
#
#  index_teams_on_band_id                                         (band_id)
#  index_teams_on_competition_id                                  (competition_id)
#  index_teams_on_competition_id_and_band_id_and_name_and_number  (competition_id,band_id,name,number) UNIQUE
#  index_teams_on_fire_sport_statistics_team_id                   (fire_sport_statistics_team_id)
#
# Foreign Keys
#
#  fk_rails_...  (applicant_id => users.id)
#  fk_rails_...  (band_id => bands.id)
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Team do
  describe '#create_assessment_requests' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, :female, competition:) }

    let(:hl) { create(:discipline, :hl, competition:) }
    let(:la) { create(:discipline, :la, competition:) }
    let(:fs) { create(:discipline, :fs, competition:) }
    let!(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
    let!(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
    let!(:assessment_fs) { create(:assessment, competition:, discipline: fs, band:) }

    let(:team) { create(:team, competition:, band:) }

    it 'creates assessment requests for all available assessments' do
      requests = team.requests.sort_by(&:relay_count)
      expect(requests.count).to eq 2
      expect(requests.first.assessment).to eq assessment_la
      expect(requests.first.relay_count).to eq 1
      expect(requests.second.assessment).to eq assessment_fs
      expect(requests.second.relay_count).to eq 2
    end
  end
end
