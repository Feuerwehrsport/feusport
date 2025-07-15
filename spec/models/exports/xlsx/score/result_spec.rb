# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Xlsx::Score::Result do
  let(:competition) { create(:competition) }
  let(:hl) { create(:discipline, :hl, competition:) }
  let(:hb) { create(:discipline, :hb, competition:) }
  let(:band) { create(:band, :female, competition:) }
  let(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
  let(:assessment_hb) { create(:assessment, competition:, discipline: hb, band:) }
  let(:result_zk) do
    Score::Result.create!(competition:, forced_name: 'Zweikampf - Frauen', multi_result_method: :sum_of_best,
                          image_key: :zk, results: [result_hb, result_hl])
  end
  let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl) }
  let(:result_hb) { create(:score_result, competition:, assessment: assessment_hb) }
  let(:person1) { create(:person, :generated, competition:, band:) }
  let(:person2) { create(:person, :generated, competition:, band:) }
  let(:person3) { create(:person, :generated, competition:, band:) }
  let(:person4) { create(:person, :generated, competition:, band:) }
  let(:list1) { create_score_list(result_hb, person1 => 1912, person2 => 2020, person3 => 2040, person4 => nil) }
  let(:list2) { create_score_list(result_hl, person1 => 2020, person2 => 1911, person3 => 3030, person4 => 1999) }

  describe 'perform' do
    context 'when single discipline' do
      context 'when result is empty' do
        it 'adds a emtpy sheet' do
          export = described_class.perform(result_hl)
          xlsx = parse_xlsx_bytestream(export.bytestream)
          expect(xlsx.sheets).to eq ['Hakenleitersteigen - Frauen']
          expect(xlsx.sheet(0).to_a).to eq [%w[Platz Vorname Nachname Mannschaft Bestzeit]]
          expect(export.filename).to eq 'hakenleitersteigen-frauen.xlsx'
        end
      end

      context 'when result has lines' do
        before { list2 }

        it 'adds a sheet' do
          export = described_class.perform(result_hl)
          xlsx = parse_xlsx_bytestream(export.bytestream)
          expect(xlsx.sheets).to eq ['Hakenleitersteigen - Frauen']
          expect(xlsx.sheet(0).to_a).to eq(
            [
              ['Platz', 'Vorname', 'Nachname', 'Mannschaft', 'Lauf 1'],
              ['1.', 'Alfred2', 'Meier2', nil, '19,11'],
              ['2.', 'Alfred4', 'Meier4', nil, '19,99'],
              ['3.', 'Alfred1', 'Meier1', nil, '20,20'],
              ['4.', 'Alfred3', 'Meier3', nil, '30,30'],
            ],
          )
          expect(export.filename).to eq 'hakenleitersteigen-frauen.xlsx'
        end
      end
    end

    context 'when zweikampf' do
      context 'when result is empty' do
        it 'adds a emtpy sheet' do
          export = described_class.perform(result_zk)
          xlsx = parse_xlsx_bytestream(export.bytestream)
          expect(xlsx.sheets).to eq ['Zweikampf - Frauen']
          expect(xlsx.sheet(0).to_a).to eq [%w[Platz Vorname Nachname Mannschaft HB HL Ergebnis]]
          expect(export.filename).to eq 'zweikampf-frauen.xlsx'
        end
      end

      context 'when result has lines' do
        before do
          list1
          list2
        end

        it 'adds a sheet' do
          export = described_class.perform(result_zk)
          xlsx = parse_xlsx_bytestream(export.bytestream)
          expect(xlsx.sheets).to eq ['Zweikampf - Frauen']
          expect(xlsx.sheet(0).to_a).to eq(
            [
              ['Platz', 'Vorname', 'Nachname', 'Mannschaft', 'HB', 'HL', 'Ergebnis'],
              ['1.', 'Alfred2', 'Meier2', nil, '20,20', '19,11', '39,31'],
              ['2.', 'Alfred1', 'Meier1', nil, '19,12', '20,20', '39,32'],
              ['3.', 'Alfred3', 'Meier3', nil, '20,40', '30,30', '50,70'],
              ['4.', 'Alfred4', 'Meier4', nil, 'o.W.', '19,99', 'o.W.'],
            ],
          )
          expect(export.filename).to eq 'zweikampf-frauen.xlsx'
        end
      end
    end
  end
end
