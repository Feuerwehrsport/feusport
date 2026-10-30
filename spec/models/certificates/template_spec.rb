# frozen_string_literal: true

require 'rails_helper'

# == Schema Information
#
# Table name: certificates_templates
#
#  id                    :uuid             not null, primary key
#  importable_for_me     :boolean          default(TRUE), not null
#  importable_for_others :boolean          default(FALSE), not null
#  name                  :string(200)      not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  competition_id        :uuid             not null
#
# Indexes
#
#  index_certificates_templates_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
RSpec.describe Certificates::Template do
  let(:competition) { create(:competition) }

  def template_with(image)
    described_class.new(competition:, name: 'Urkunde', image:)
  end

  describe 'background formats' do
    it 'accepts a single A4 portrait PDF' do
      template = template_with(background_pdf_upload)
      expect(template).to be_valid
      expect(template.image_pdf?).to be true
    end

    it 'rejects PDFs with several pages' do
      template = template_with(background_pdf_upload(pages: 2))
      expect(template).not_to be_valid
      expect(template.errors.details[:image]).to include(error: :pdf_single_page)
    end

    it 'rejects PDFs that are not A4 portrait' do
      template = template_with(background_pdf_upload(layout: :landscape))
      expect(template).not_to be_valid
      expect(template.errors.details[:image]).to include(error: :pdf_a4_portrait)
    end

    it 'rejects broken PDFs' do
      template = template_with(background_upload("%PDF-1.4\nkaputt", 'kaputt.pdf', 'application/pdf'))
      expect(template).not_to be_valid
    end

    it 'accepts other raster formats and rejects SVG' do
      expect(template_with(background_webp_upload)).to be_valid

      svg = template_with(background_upload('<svg xmlns="http://www.w3.org/2000/svg"/>', 'bild.svg', 'image/svg+xml'))
      expect(svg).not_to be_valid
    end

    it 'checks PDFs only when uploaded' do
      template = template_with(background_pdf_upload)
      template.save!
      expect(described_class.find(template.id)).to be_valid
    end

    it 'keeps PDF backgrounds when duplicating' do
      template = template_with(background_pdf_upload)
      template.save!

      duplicate = template.duplicate_to(create(:competition, name: 'Anderer Cup'))
      expect(duplicate).to be_persisted
      expect(duplicate.image_pdf?).to be true
    end
  end
end
