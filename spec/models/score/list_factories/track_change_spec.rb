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

RSpec.describe Score::ListFactories::TrackChange do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:discipline) { create(:discipline, :hl, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:before_assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:before_result) { create(:score_result, competition:, assessment:) }

  let(:before_list) { create(:score_list, competition:, assessments: [before_assessment], results: [before_result]) }

  let(:factory) do
    described_class.new(
      competition:, session_id: '1',
      discipline:, assessments: [assessment], name: 'long name',
      shortcut: 'short', track_count: 2, results: [result],
      before_list:
    )
  end

  describe 'validation' do
    it 'compares assessment from list and before_list' do
      expect(factory).not_to be_valid
      expect(factory.errors.attribute_names).to include(:before_list)
    end

    context 'with same assessment' do
      let(:before_assessment) { assessment }

      it 'is valid' do
        expect(factory).to be_valid
      end
    end
  end

  describe '#perform' do
    let(:before_assessment) { assessment }
    let(:person1) { create(:person, :generated, competition:, band:) }
    let(:person2) { create(:person, :generated, competition:, band:) }
    let(:person3) { create(:person, :generated, competition:, band:) }

    before do
      create(:score_list_entry, list: before_list, competition:, assessment:, entity: person1, run: 1, track: 1)
      create(:score_list_entry, list: before_list, competition:, assessment:, entity: person2, run: 1, track: 2)
      create(:score_list_entry, list: before_list, competition:, assessment:, entity: person3, run: 2, track: 1)
    end

    it 'copies entries and changes tracks' do
      new_list = factory.list
      expect { factory.perform }.to change(Score::ListEntry, :count).by(3)

      expect(new_list.entries.reload.map { |e| [e.entity, e.run, e.track] }).to eq [
        [person2, 1, 1], [person1, 1, 2], [person3, 2, 2]
      ]
    end
  end
end
