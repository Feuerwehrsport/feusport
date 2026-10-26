# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CertificatesHelper do
  let(:competition) { create(:competition) }

  it 'uses the image itself for browser formats and a preview for PDFs' do
    png = create(:certificates_template, competition:)
    expect(helper.certificates_background_path(png)).to include('/rails/active_storage/blobs/')

    pdf = Certificates::Template.create!(competition:, name: 'PDF', image: background_pdf_upload)
    expect(helper.certificates_background_path(pdf)).to include('/rails/active_storage/representations/')
  end
end
