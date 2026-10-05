# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamImport do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }

  describe '#save' do
    it 'creates teams' do
      import = described_class.new(competition:, band_id: band.id, import_rows: "Rostock\nFF Warin\n")
      expect { expect(import.save).to be true }.to change(Team, :count).by(2)
    end

    context 'when saving a team fails' do
      it 'adds error to import_rows' do
        import = described_class.new(competition:, band_id: band.id, import_rows: "Rostock\nRostock")
        expect(import.teams.count).to eq 2

        expect(import.save).to be false
        expect(import.errors.attribute_names).to eq [:import_rows]
        expect(import.errors[:import_rows].first).to include('Name ist bereits vergeben')
      end
    end
  end
end
