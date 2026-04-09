# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::FullDump do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:hint) { "Text\nNeue Zeile" }
  let!(:result) { create(:score_result, competition:) }
  let(:dump) { described_class.new(competition, user, hint) }
  let!(:competition_result) { Score::CompetitionResult.create!(name: 'Frauen', competition:, result_type: 'dcup') }

  let(:created_files) do
    [
      'ergebnis-hakenleitersteigen-frauen.pdf',
      'ergebnis-hakenleitersteigen-frauen.json',
      'gesamtwertung-frauen.pdf',
    ]
  end

  describe 'new' do
    it 'creates files' do
      expect(dump.send(:files).map(&:name)).to eq created_files

      hash = dump.to_export_hash
      expect(hash.except(:files)).to eq(
        name: 'MV-Cup',
        date: '2024-02-29',
        place: 'Rostock',
        hint: "Text\nNeue Zeile",
        url: 'http://www.example.com/2024/mv-cup',
        user: 'Alfred Meier',
        user_email_address: 'alfred@meier.de',
        person_points_corrections: [],
        team_points_corrections: [],
      )
      expect(hash[:files].count).to eq(created_files.count)
      expect(hash[:files].first.except(:base64_data)).to eq(
        name: created_files.first, mimetype: 'application/pdf',
      )

      expect(JSON.parse(Zlib::Inflate.inflate(Base64.decode64(dump.to_export_data)), symbolize_names: true)).to eq(hash)
    end
  end
end
