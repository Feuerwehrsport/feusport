# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factories
#
#  id                       :uuid             not null, primary key
#  best_count               :integer
#  hidden                   :boolean          default(FALSE), not null
#  name                     :string(100)
#  separate_target_times    :boolean
#  shortcut                 :string(50)
#  show_best_of_run         :boolean          default(FALSE), not null
#  single_competitors_first :boolean          default(TRUE), not null
#  status                   :string(50)
#  track                    :integer
#  track_count              :integer
#  type                     :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  before_list_id           :uuid
#  before_result_id         :uuid
#  competition_id           :uuid             not null
#  discipline_id            :uuid             not null
#  session_id               :string(200)      not null
#
# Indexes
#
#  index_score_list_factories_on_before_list_id    (before_list_id)
#  index_score_list_factories_on_before_result_id  (before_result_id)
#  index_score_list_factories_on_competition_id    (competition_id)
#  index_score_list_factories_on_discipline_id     (discipline_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Score::ListFactory do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:discipline) { create(:discipline, :hl, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:older_result) { create(:score_result, competition:, assessment:) }

  let(:created_list) { Score::List.last }

  describe 'steps' do
    it 'goes through steps' do
      instance = described_class.create!(competition:, discipline:, next_step: 'assessments', session_id: '1',
                                         type: 'Score::ListFactory')
      expect(instance.current_step).to eq :assessments
      instance.update!(assessment_ids: [assessment.id], next_step: 'names')

      expect(instance.current_step).to eq :names
      expect(instance.default_name).to eq 'Hakenleitersteigen - Frauen - Lauf 1'
      expect(instance.default_shortcut).to eq 'Lauf 1'
      instance.update!(name: 'long name', shortcut: 'short', next_step: 'tracks')

      expect(instance.current_step).to eq :tracks
      expect(instance.default_track_count).to eq 2
      instance.update!(track_count: '3', next_step: 'results')

      expect(instance.current_step).to eq :results

      instance.update!(result_ids: [result.id], next_step: 'generator')
      expect(instance.current_step).to eq :generator
      instance.update!(type: 'Score::ListFactories::Best', next_step: 'generator_params')
      expect(instance.current_step).to eq :generator_params
      instance.update!(before_result: older_result, best_count: 10, next_step: 'finish')
      expect(instance.current_step).to eq :finish

      expect do
        instance.update!(next_step: 'create')
        expect(instance.current_step).to eq :create
      end.to change(Score::List, :count).by(1)

      expect(created_list.name).to eq 'long name'
      expect(created_list.shortcut).to eq 'short'
      expect(created_list.track_count).to eq 3
      expect(created_list.assessments).to eq [assessment]
      expect(created_list.results).to eq [result]
      expect(created_list.entries).to eq []
    end
  end

  describe '#for_run_and_track_for' do
    let(:factory) do
      Score::ListFactories::Simple.create!(
        competition:, session_id: '1',
        discipline:, assessments: [assessment], name: 'long name',
        shortcut: 'short', track_count: 2, results: [result]
      )
    end
    let(:rows) { [1, 2, 3, 4, 5] }

    it 'calls create_list_entry for each run and track' do
      factory.list
      expect(factory).to receive(:create_list_entry).with(1, 1, 1)
      expect(factory).to receive(:create_list_entry).with(2, 1, 2)
      expect(factory).to receive(:create_list_entry).with(3, 2, 1)
      expect(factory).to receive(:create_list_entry).with(4, 2, 2)
      expect(factory).to receive(:create_list_entry).with(5, 3, 1)
      factory.send(:for_run_and_track_for, rows)
    end
  end
end
