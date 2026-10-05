# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Band do
  let(:competition) { create(:competition) }

  describe '#<=>' do
    it 'sorts by position, name and id' do
      band1 = create(:band, competition:, name: 'Frauen')
      band2 = create(:band, :male, competition:, name: 'Männer')

      expect(band1 <=> band2).to eq(-1)
      expect(band2 <=> band1).to eq 1

      band2.position = band1.position
      expect(band1 <=> band2).to eq(-1)

      band2.name = band1.name
      expect(band1 <=> band2).to eq(band1.to_key <=> band2.to_key)
      expect(band1 <=> band2).not_to eq 0
    end
  end

  describe 'tag names' do
    let(:band) { create(:band, competition:) }

    it 'parses and joins person tags' do
      band.person_tag_names = ' Zeta, Alpha ,, Beta '
      expect(band.person_tags).to eq %w[Alpha Beta Zeta]
      expect(band.person_tag_names).to eq 'Alpha, Beta, Zeta'

      band.person_tag_names = nil
      expect(band.person_tags).to eq []
    end

    it 'parses and joins team tags' do
      band.team_tag_names = 'U20, Ü40,'
      expect(band.team_tags).to eq %w[U20 Ü40]
      expect(band.team_tag_names).to eq 'U20, Ü40'

      band.team_tag_names = ''
      expect(band.team_tags).to eq []
    end
  end
end
