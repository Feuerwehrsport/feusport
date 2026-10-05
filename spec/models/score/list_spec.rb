# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::List do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let(:assessment) { create(:assessment, competition:, band:, discipline:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:list) { create(:score_list, competition:, assessments: [assessment], results: [result]) }

  describe '#discipline_klass and #column_count' do
    context 'when discipline is a single discipline' do
      let(:discipline) { create(:discipline, :hl, competition:) }

      it 'uses people' do
        expect(list.discipline_klass).to eq Person
        expect(list.column_count).to eq 6
      end
    end

    context 'when discipline is like fire relay' do
      let(:discipline) { create(:discipline, :fs, competition:) }

      it 'uses team relays' do
        expect(list.discipline_klass).to eq TeamRelay
        expect(list.column_count).to eq 4
      end
    end

    context 'when discipline is a group discipline' do
      let(:discipline) { create(:discipline, :la, competition:) }

      it 'uses teams' do
        expect(list.discipline_klass).to eq Team
        expect(list.column_count).to eq 4
      end
    end
  end
end
