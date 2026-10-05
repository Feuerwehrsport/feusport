# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Xlsx::Teams do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:la) { create(:discipline, :la, competition:) }
  let(:gs) { create(:discipline, :gs, competition:) }
  let!(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
  let!(:assessment_gs) { create(:assessment, competition:, discipline: gs, band:) }
  let!(:team) { create(:team, competition:, band:, name: 'FF Warin', shortcut: 'Warin') }

  describe 'perform' do
    before do
      team.requests.find_by(assessment: assessment_gs).destroy!
      team.requests.find_by(assessment: assessment_la).update!(assessment_type: :out_of_competition)
    end

    it 'marks requested assessments with assessment type' do
      export = described_class.perform(competition, false)
      xlsx = parse_xlsx_bytestream(export.bytestream)
      expect(xlsx.sheets).to eq ['Frauen']
      expect(xlsx.sheet(0).to_a).to eq [
        ['Name', 'Wettkä.', 'Abkürzung', 'Gruppenstafette', 'Löschangriff Nass'],
        ['FF Warin', '-', 'Warin', nil, 'A'],
      ]
    end
  end
end
