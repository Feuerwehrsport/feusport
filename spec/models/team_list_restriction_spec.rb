# frozen_string_literal: true

# == Schema Information
#
# Table name: team_list_restrictions
#
#  id             :uuid             not null, primary key
#  restriction    :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  discipline_id  :uuid             not null
#  team1_id       :uuid             not null
#  team2_id       :uuid             not null
#
# Indexes
#
#  index_team_list_restrictions_on_competition_id  (competition_id)
#  index_team_list_restrictions_on_discipline_id   (discipline_id)
#  index_team_list_restrictions_on_team1_id        (team1_id)
#  index_team_list_restrictions_on_team2_id        (team2_id)
#  index_team_list_restrictions_unique             (team1_id,team2_id,discipline_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (discipline_id => disciplines.id)
#  fk_rails_...  (team1_id => teams.id)
#  fk_rails_...  (team2_id => teams.id)
#
require 'rails_helper'

RSpec.describe TeamListRestriction do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, competition:) }
  let!(:discipline) { create(:discipline, :la, competition:) }
  let!(:team1) { create(:team, competition:, band:) }
  let(:t1) { team1.id }
  let!(:team2) { create(:team, competition:, band:) }
  let(:t2) { team2.id }
  let(:restriction) { :before }
  let(:instance) { described_class.new(team1:, team2:, competition:, discipline:, restriction:) }

  describe 'validation' do
    it 'checks for diffent teams' do
      expect(instance).to be_valid

      instance.team2 = team1
      expect(instance).not_to be_valid
      expect(instance.errors.messages).to eq(team1: ['darf nicht gleich Frauen-Team 1 Frauen sein'])
    end
  end

  describe 'TeamListRestriction::Check' do
    it 'validates all matching restrictions' do
      instance.save
      check = TeamListRestriction::Check.new(instance)
      expect(check.valid?([[t1, 2], [t2, 2]])).to be false
      expect(check.errors).to eq [instance]
    end
  end

  describe 'validation of check with softer modes' do
    context 'when restriction is not_same_run' do
      let(:restriction) { :not_same_run }

      it 'checks restriction' do
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 0)).to be false

        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 1)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 2)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 3)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 4)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 5)).to be true
      end
    end

    context 'when restriction is same_run' do
      let(:restriction) { :same_run }

      it 'checks restriction' do
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 0)).to be false

        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 1)).to be false
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 2)).to be false
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 3)).to be true
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 4)).to be true
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 5)).to be true
      end
    end

    context 'when restriction is before' do
      let(:restriction) { :before }

      it 'checks restriction' do
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 0)).to be false

        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 1)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 2)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 3)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 4)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 5)).to be true
      end
    end

    context 'when restriction is after' do
      let(:restriction) { :after }

      it 'checks restriction' do
        expect(instance.list_entries_valid?([[t1, 3], [t2, 2]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 3]], 0)).to be false

        expect(instance.list_entries_valid?([[t1, 2], [t2, 3]], 1)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 3]], 2)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 3]], 3)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 3]], 4)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 3]], 5)).to be true
      end
    end

    context 'when restriction is distance1' do
      let(:restriction) { :distance1 }

      it 'checks restriction' do
        expect(instance.list_entries_valid?([[t1, 1], [t2, 3]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 1], [t2, 4]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 4], [t2, 1]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 4], [t2, 2]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 0)).to be false

        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 1)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 2)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 3)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 4)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 5)).to be true
      end
    end

    context 'when restriction is distance2' do
      let(:restriction) { :distance2 }

      it 'checks restriction' do
        expect(instance.list_entries_valid?([[t1, 1], [t2, 4]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 1], [t2, 5]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 5], [t2, 1]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 5], [t2, 2]], 0)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 2]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 1], [t2, 2]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 1], [t2, 3]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 0)).to be false
        expect(instance.list_entries_valid?([[t1, 3], [t2, 1]], 0)).to be false

        expect(instance.list_entries_valid?([[t1, 3], [t2, 1]], 1)).to be true
        expect(instance.list_entries_valid?([[t1, 2], [t2, 1]], 1)).to be false
        expect(instance.list_entries_valid?([[t1, 3], [t2, 1]], 2)).to be true
        expect(instance.list_entries_valid?([[t1, 3], [t2, 1]], 3)).to be true
        expect(instance.list_entries_valid?([[t1, 3], [t2, 1]], 4)).to be true
        expect(instance.list_entries_valid?([[t1, 3], [t2, 1]], 5)).to be true
      end
    end
  end
end
