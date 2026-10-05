# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Xlsx::Score::List do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:la) { create(:discipline, :la, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline: la, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:team) { create(:team, competition:, band:, name: 'FF Warin') }
  let(:list) do
    create(:score_list, competition:, name: 'Löschangriff - Lauf 1', assessments: [assessment], results: [result],
                        separate_target_times: true)
  end

  before do
    create(:score_list_entry, list:, competition:, entity: team, assessment:, run: 1, track: 1,
                              result_type: :valid, time_left_target: 2000, time_right_target: 2210)
  end

  describe 'perform' do
    it 'adds sheet with target times' do
      export = described_class.perform(list.reload)
      xlsx = parse_xlsx_bytestream(export.bytestream)
      expect(xlsx.sheets).to eq ['Löschangriff - Lauf 1']
      expect(xlsx.sheet(0).to_a).to eq [
        %w[Lauf Bahn Mannschaft Ziele Zeit],
        [1, 1, 'FF Warin', 'L: 20,00, R: 22,10', '22,10'],
        [nil, 2, nil, nil, nil],
      ]
      expect(export.filename).to eq 'loschangriff-lauf-1.xlsx'
    end
  end

  describe 'with multiple assessments' do
    let(:male) { create(:band, :male, competition:) }
    let(:assessment_male) { create(:assessment, competition:, discipline: la, band: male) }
    let(:team_male) { create(:team, competition:, band: male, name: 'FF Goldberg') }

    it 'adds assessment hint as plain text' do
      list.update!(assessments: [assessment, assessment_male])
      create(:score_list_entry, list:, competition:, entity: team_male, assessment: assessment_male, run: 1, track: 2,
                                result_type: :valid, time_left_target: 2100, time_right_target: 2300)

      xlsx = parse_xlsx_bytestream(described_class.perform(list.reload).bytestream)
      expect(xlsx.sheet(0).to_a).to eq [
        %w[Lauf Bahn Mannschaft Ziele Zeit],
        [1, 1, 'FF Warin (Löschangriff Nass - Frauen)', 'L: 20,00, R: 22,10', '22,10'],
        [nil, 2, 'FF Goldberg (Löschangriff Nass - Männer)', 'L: 21,00, R: 23,00', '23,00'],
      ]
    end
  end
end
