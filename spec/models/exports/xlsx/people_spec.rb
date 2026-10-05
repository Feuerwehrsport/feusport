# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Xlsx::People do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:hl) { create(:discipline, :hl, competition:) }
  let(:hb) { create(:discipline, :hb, competition:) }
  let!(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
  let!(:assessment_hb) { create(:assessment, competition:, discipline: hb, band:) }
  let!(:person) { create(:person, competition:, band:, first_name: 'Tom', last_name: 'Gehlert') }

  describe 'perform' do
    before do
      create(:assessment_request, assessment: assessment_hl, entity: person, assessment_type: :out_of_competition)
    end

    it 'leaves cells of not requested assessments empty' do
      export = described_class.perform(competition)
      xlsx = parse_xlsx_bytestream(export.bytestream)
      expect(xlsx.sheets).to eq ['Frauen']
      expect(xlsx.sheet(0).to_a).to eq [
        %w[Nachname Vorname Mannschaft 100m-Hindernisbahn Hakenleitersteigen],
        ['Gehlert', 'Tom', nil, nil, 'A'],
      ]
    end
  end
end
