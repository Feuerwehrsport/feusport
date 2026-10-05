# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#documents_link_array' do
    let(:competition) { create(:competition) }

    it 'returns empty list without documents' do
      expect(helper.documents_link_array(competition)).to eq []
    end

    it 'returns links with preview for representable documents' do
      document = create(:document, competition:, title: 'Lageplan',
                                   file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/pixel.jpg')))
      base = "/#{competition.year}/#{competition.slug}"

      expect(helper.documents_link_array(competition.reload)).to eq [
        {
          title: 'Lageplan',
          preview: "#{base}/dp/#{document.idpart}",
          url: "#{base}/dd/#{document.idpart}",
          image: "#{base}/di/#{document.idpart}",
        },
      ]
    end

    it 'returns links without preview for not representable documents' do
      document = create(:document, competition:)
      allow(document.file).to receive(:representable?).and_return(false)
      allow(competition).to receive(:documents).and_return([document])
      base = "/#{competition.year}/#{competition.slug}"

      expect(helper.documents_link_array(competition)).to eq [
        { title: 'Ausschreibung', preview: false, url: "#{base}/dd/#{document.idpart}" },
      ]
    end
  end
end
