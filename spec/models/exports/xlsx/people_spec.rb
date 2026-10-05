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
  let(:team) { create(:team, competition:, band:, name: 'Warin', shortcut: 'Warin') }
  let!(:person_with_team) { create(:person, competition:, band:, team:, first_name: 'Anna', last_name: 'Albers') }

  describe 'perform' do
    before do
      create(:assessment_request, assessment: assessment_hl, entity: person, assessment_type: :single_competitor,
                                  single_competitor_order: 2)
      create(:assessment_request, assessment: assessment_hl, entity: person_with_team,
                                  assessment_type: :single_competitor, single_competitor_order: 2)
      create(:assessment_request, assessment: assessment_hb, entity: person_with_team,
                                  assessment_type: :out_of_competition)
    end

    it 'shows short types and leaves cells of not requested assessments empty' do
      export = described_class.perform(competition)
      xlsx = parse_xlsx_bytestream(export.bytestream)
      expect(xlsx.sheets).to eq ['Frauen']
      expect(xlsx.sheet(0).to_a).to eq [
        %w[Nachname Vorname Mannschaft 100m-Hindernisbahn Hakenleitersteigen],
        %w[Albers Anna Warin A E2],
        ['Gehlert', 'Tom', nil, nil, 'E'],
      ]
    end
  end
end
