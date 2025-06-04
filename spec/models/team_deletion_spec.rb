# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamDeletion do
  describe 'validates deletion' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, :female, competition:) }
    let(:hl) { create(:discipline, :hl, competition:) }
    let(:la) { create(:discipline, :la, competition:) }
    let(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
    let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl) }
    let(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
    let(:result_la) { create(:score_result, competition:, assessment: assessment_la) }

    let(:team) { create(:team, competition:, band:, applicant: competition.users.first) }
    let(:person) { create(:person, competition:, band:, team:) }

    let(:deletion) { described_class.new(competition:, team:) }

    context 'when list entries for team exists' do
      let!(:list_la) { create_score_list(result_la, team => 2413) }

      it 'fails if confirm not set' do
        expect(deletion).not_to be_valid
        expect(deletion.errors.attribute_names).to eq [:confirm]

        expect do
          deletion.confirm = true
          expect(deletion).to be_valid
          expect(deletion.save).to be_truthy
        end.to change(Team, :count).by(-1)
      end
    end

    context 'when no list entries for team exists' do
      before { team } # create

      it 'dont need confirm' do
        expect do
          deletion.confirm = false
          expect(deletion).to be_valid
          expect(deletion.save).to be_truthy
        end.to change(Team, :count).by(-1)
      end
    end

    context 'when a person with scores exists' do
      let!(:list_hl) { create_score_list(result_hl, person => 1912) }

      it 'fails' do
        expect(Person.first.applicant).to be_nil

        deletion.delete_people = true
        expect(deletion).not_to be_valid
        expect(deletion.errors.attribute_names).to eq [:delete_people]

        expect do
          expect do
            deletion.delete_people = false
            expect(deletion).to be_valid
            expect(deletion.save).to be_truthy
          end.not_to change(Person, :count)
        end.to change(Team, :count).by(-1)

        expect(Person.first.applicant).not_to be_nil
      end
    end

    context 'when a person without scores exists' do
      before { person } # create

      it 'fails' do
        deletion.delete_people = true

        expect do
          expect do
            expect(deletion).to be_valid
            expect(deletion.save).to be_truthy
          end.to change(Person, :count).by(-1)
        end.to change(Team, :count).by(-1)
      end
    end
  end
end
