# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :uuid             not null, primary key
#  certificate_name              :string
#  enrolled                      :boolean          default(FALSE), not null
#  lottery_number                :integer
#  multi_team                    :boolean          default(FALSE), not null
#  name                          :string(100)      not null
#  number                        :integer          default(1), not null
#  registration_hint             :text
#  shortcut                      :string(50)       default(""), not null
#  tags                          :string           default([]), is an Array
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
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

  describe '#<=>' do
    let(:competition) { create(:competition) }
    let(:female) { create(:band, :female, competition:) }
    let(:male) { create(:band, :male, competition:) }

    it 'sorts by full name and then by id' do
      team_b = create(:team, competition:, band: female, name: 'Bad Doberan')
      team_a1 = create(:team, competition:, band: female, name: 'Ahrenshagen')
      team_a2 = create(:team, competition:, band: male, name: 'Ahrenshagen')

      expect(team_a1 <=> team_b).to eq(-1)
      expect(team_b <=> team_a1).to eq 1
      expect(team_a1.full_name).to eq team_a2.full_name
      expect(team_a1 <=> team_a2).to eq(team_a1.id <=> team_a2.id)
      expect(team_a1 <=> team_a2).not_to eq 0
    end
  end

  describe '#export_gender' do
    it 'returns gender of band' do
      expect(build(:team, band: build(:band, :male)).export_gender).to eq 'male'
      expect(described_class.new.export_gender).to be_nil
    end
  end

  describe 'GroupAssessmentValidator' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, :female, competition:) }
    let(:hl) { create(:discipline, :hl, competition:) }
    let(:assessment) { create(:assessment, competition:, discipline: hl, band:) }
    let!(:result) do
      create(:score_result, competition:, assessment:, group_assessment: true, group_run_count: 2,
                            forced_name: 'Gruppenwertung')
    end
    let(:team) { create(:team, competition:, band:) }

    it 'is valid without people' do
      validator = described_class::GroupAssessmentValidator.new(team)
      expect(validator).to be_valid
      expect(validator.messages).to eq ''
    end

    it 'checks group competitor count' do
      people = create_list(:person, 3, :generated, competition:, band:, team:)
      people.first(2).each do |person|
        create(:assessment_request, assessment:, entity: person, assessment_type: :group_competitor)
      end
      create(:assessment_request, assessment:, entity: people.last, assessment_type: :single_competitor)

      expect(described_class::GroupAssessmentValidator.new(team)).to be_valid

      people.last.requests.first.update!(assessment_type: :group_competitor)
      validator = described_class::GroupAssessmentValidator.new(team)
      expect(validator).not_to be_valid
      expect(validator.messages).to eq "#{result.name}: 3 von 2"
    end
  end
end
