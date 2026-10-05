# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Pdf::Score::Result do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:la) { create(:discipline, :la, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline: la, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:team) { create(:team, competition:, band:, name: 'FF Warin') }
  let(:list) do
    create(:score_list, competition:, name: 'Löschangriff - Lauf 1', shortcut: 'Lauf 1', assessments: [assessment],
                        results: [result], separate_target_times: true)
  end

  before do
    create(:score_list_entry, list:, competition:, entity: team, assessment:, run: 1, track: 1,
                              result_type: :valid, time_left_target: 2000, time_right_target: 2210)
  end

  describe 'build_data_rows' do
    it 'adds target times for lists with separate target times' do
      export = described_class.new(result.reload, nil)
      expect(export.build_data_rows(result, true, pdf: true)).to eq [
        ['Platz', 'Mannschaft', { content: 'Lauf 1', colspan: 2 }],
        ['1.', 'FF Warin',
         { content: "<font size='6'>L: 20,00<br/>R: 22,10</font>", inline_format: true, padding: [0, 0, 3, 0],
           valign: :center },
         '22,10'],
      ]
    end

    it 'does not add target times for non pdf exports' do
      export = described_class.new(result.reload, nil)
      expect(export.build_data_rows(result, true)).to eq [
        ['Platz', 'Mannschaft', 'Lauf 1'],
        ['1.', 'FF Warin', '22,10'],
      ]
    end
  end

  describe 'perform' do
    it 'renders pdf' do
      export = described_class.perform(result.reload, 'single_competitors')
      expect(export.bytestream).to start_with('%PDF')
      expect(export.pdf.page_count).to eq 1
    end
  end
end
