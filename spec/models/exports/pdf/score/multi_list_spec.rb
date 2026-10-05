# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Pdf::Score::MultiList do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:la) { create(:discipline, :la, competition:) }
  let(:gs) { create(:discipline, :gs, competition:) }
  let(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
  let(:assessment_gs) { create(:assessment, competition:, discipline: gs, band:) }
  let(:result_la) { create(:score_result, competition:, assessment: assessment_la) }
  let(:result_gs) { create(:score_result, competition:, assessment: assessment_gs) }
  let(:team) { create(:team, competition:, band:, name: 'FF Warin') }
  let(:list_la) do
    create(:score_list, competition:, name: 'Löschangriff - Lauf 1', assessments: [assessment_la],
                        results: [result_la], separate_target_times: true)
  end
  let(:list_gs) do
    create(:score_list, competition:, name: 'Gruppenstafette - Lauf 1', assessments: [assessment_gs],
                        results: [result_gs])
  end

  before do
    create(:score_list_entry, list: list_la, competition:, entity: team, assessment: assessment_la, run: 1, track: 1,
                              result_type: :valid, time_left_target: 2000, time_right_target: 2210)
    create(:score_list_entry, list: list_gs, competition:, entity: team, assessment: assessment_gs, run: 1, track: 1,
                              result_type: :valid, time: 3000)
  end

  describe 'perform' do
    it 'renders lists in columns and pages' do
      export = described_class.new(competition, [list_la.reload, 'column', list_gs.reload, 'column', 'page'])
      allow(export.pdf).to receive(:start_new_page).and_call_original
      export.unicode_perform

      # once after second column, once for 'page'
      expect(export.pdf).to have_received(:start_new_page).twice
      expect(export.pdf.page_count).to eq 3
      expect(export.filename).to eq 'startlisten.pdf'
    end
  end

  describe 'show_export_data' do
    it 'shows target times as columns' do
      export = described_class.new(competition, [])
      data = export.show_export_data(list_la, pdf: true, show_bib_numbers: false, hint_size: 4,
                                              separate_target_times_as_columns: true)
      expect(data.first).to eq %w[Lauf Bahn Mannschaft Links Rechts Zeit]
      expect(data.second).to eq [1, 1, { content: 'FF Warin', inline_format: true }, '20,00', '22,10', '22,10']
    end
  end

  describe 'column_widths' do
    it 'uses widths depending on list type' do
      hl = create(:discipline, :hl, competition:)
      assessment_hl = create(:assessment, competition:, discipline: hl, band:)
      list_hl = create(:score_list, competition:, assessments: [assessment_hl],
                                    results: [create(:score_result, competition:, assessment: assessment_hl)])
      export = described_class.new(competition, [])
      expect(export.column_widths(list_hl)).to eq(0 => 15, 1 => 16, 2 => 70, 3 => 60, 4 => 75, 5 => 22)
      expect(export.column_widths(list_la)).to eq(0 => 18, 1 => 18, 2 => 157, 3 => 20, 4 => 20, 5 => 25)
      expect(export.column_widths(list_gs)).to eq(0 => 18, 1 => 18, 2 => 197, 3 => 25)
    end
  end
end
