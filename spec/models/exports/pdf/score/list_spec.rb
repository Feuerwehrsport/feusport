# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Pdf::Score::List do
  let(:competition) { create(:competition) }
  let(:la) { create(:discipline, :la, competition:) }
  let(:female) { create(:band, :female, competition:) }
  let(:male) { create(:band, :male, competition:) }
  let(:assessment_female) { create(:assessment, competition:, discipline: la, band: female) }
  let(:assessment_male) { create(:assessment, competition:, discipline: la, band: male) }
  let(:result_female) { create(:score_result, competition:, assessment: assessment_female) }
  let(:result_male) { create(:score_result, competition:, assessment: assessment_male) }
  let(:team_female1) { create(:team, competition:, band: female, name: 'FF Warin') }
  let(:team_female2) { create(:team, competition:, band: female, name: 'FF Gadebusch') }
  let(:team_female3) { create(:team, competition:, band: female, name: 'FF Bützow') }
  let(:team_male) { create(:team, competition:, band: male, name: 'FF Lübtheen') }
  let(:list) do
    create(:score_list, competition:, name: 'Löschangriff - Lauf 1', assessments: [assessment_female, assessment_male],
                        results: [result_female, result_male], separate_target_times: true, show_best_of_run: true,
                        track_count: 3)
  end

  def create_entry(entity, assessment, run:, track:, left: nil, right: nil, **)
    create(:score_list_entry, list:, competition:, entity:, assessment:, run:, track:,
                              result_type: left && right ? :valid : :invalid,
                              time_left_target: left, time_right_target: right, **)
  end

  def targets(content)
    { content: "<font size='6'>#{content}</font>", inline_format: true, padding: [0, 0, 3, 0], valign: :center }
  end

  before do
    create_entry(team_female1, assessment_female, run: 1, track: 1, left: 2000, right: 2210)
    create_entry(team_male, assessment_male, run: 1, track: 2, left: 1900, right: 2100,
                                             assessment_type: :out_of_competition)
    create_entry(team_female3, assessment_female, run: 1, track: 3, left: 2300, right: 2400)
    create_entry(team_female2, assessment_female, run: 2, track: 1)
    list.reload
  end

  describe 'show_export_data' do
    it 'adds target times and assessment hints for pdf' do
      export = described_class.new(list, false)
      expect(export.show_export_data(list, pdf: true)).to eq [
        %w[Lauf Bahn Mannschaft Ziele Zeit],
        [1, 1, { content: "FF Warin<font size='6'> (Löschangriff Nass - Frauen)</font>", inline_format: true },
         targets('L: 20,00<br/>R: 22,10'), '22,10'],
        ['', 2,
         { content: "FF Lübtheen<font size='6'><strikethrough> (Löschangriff Nass - Männer)</strikethrough></font>",
           inline_format: true },
         targets('L: 19,00<br/>R: 21,00'), '21,00'],
        ['', 3, { content: "FF Bützow<font size='6'> (Löschangriff Nass - Frauen)</font>", inline_format: true },
         targets('L: 23,00<br/>R: 24,00'), '24,00'],
        [2, 1, { content: "FF Gadebusch<font size='6'> (Löschangriff Nass - Frauen)</font>", inline_format: true },
         targets(''), 'o.W.'],
        ['', 2, { content: nil, inline_format: true }, nil, nil],
        ['', 3, { content: nil, inline_format: true }, nil, nil],
      ]
    end

    it 'adds target times as separate columns' do
      export = described_class.new(list, false)
      data = export.show_export_data(list, separate_target_times_as_columns: true)
      expect(data.first).to eq %w[Lauf Bahn Mannschaft Links Rechts Zeit]
      expect(data.second).to eq [1, 1, 'FF Warin (Löschangriff Nass - Frauen)', '20,00', '22,10', '22,10']
      expect(data[4]).to eq [2, 1, 'FF Gadebusch (Löschangriff Nass - Frauen)', '', '', 'o.W.']
    end

    it 'does not add assessment hints when disabled' do
      list.update!(show_multiple_assessments: false)
      export = described_class.new(list, false)
      expect(export.show_export_data(list).second).to eq [1, 1, 'FF Warin', 'L: 20,00, R: 22,10', '22,10']
    end
  end

  describe 'score_list_entries' do
    it 'marks best entry per assessment and run' do
      export = described_class.new(list, false)
      bests = []
      export.score_list_entries(list) { |entry, run, track, best| bests.push([entry&.entity&.name, run, track, best]) }
      expect(bests).to eq [
        ['FF Warin', 1, 1, true],
        ['FF Lübtheen', 1, 2, true],
        ['FF Bützow', 1, 3, false],
        ['FF Gadebusch', 2, 1, false],
        [nil, 2, 2, false],
        [nil, 2, 3, false],
      ]
    end
  end

  describe 'perform' do
    it 'uses smaller columns for target times' do
      export = described_class.perform(list, false)
      expect(export.send(:column_widths)).to eq(0 => 35, 1 => 35, -1 => 40, -2 => 40)
      expect(export.bytestream).to start_with('%PDF')
      expect(export.pdf.page_count).to eq 1
      expect(export.filename).to eq 'loschangriff-lauf-1.pdf'
    end

    it 'uses more columns for judges' do
      export = described_class.perform(list, true)
      expect(export.send(:column_widths)).to eq(0 => 35, 1 => 35, -1 => 40, -2 => 40, -3 => 40)
      expect(export.show_export_data(list, more_columns: true).first).to eq ['Lauf', 'Bahn', 'Mannschaft', '', '', '']
      expect(export.filename).to eq 'loschangriff-lauf-1-kampfrichter.pdf'
    end
  end

  describe 'fit_in' do
    let(:export) { described_class.new(list, false) }

    it 'reduces font size for long names in pdf' do
      expect(export.fit_in('a' * 15, pdf: true)).to eq 'a' * 15
      expect(export.fit_in('a' * 16, pdf: true)).to eq(content: 'a' * 16, size: 9)
      expect(export.fit_in('a' * 20, pdf: true)).to eq(content: 'a' * 20, size: 8)
      expect(export.fit_in('a' * 24, pdf: true)).to eq(content: 'a' * 24, size: 7)
      expect(export.fit_in('a' * 28, pdf: true)).to eq(content: 'a' * 28, size: 6)
      expect(export.fit_in('a' * 32, pdf: true)).to eq(content: 'a' * 32, size: 5)
      expect(export.fit_in('a' * 32, pdf: false)).to eq 'a' * 32
      expect(export.fit_in(nil, pdf: true)).to eq ''
    end
  end
end
