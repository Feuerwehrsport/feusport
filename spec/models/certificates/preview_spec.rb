# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Certificates::Preview do
  let(:competition) { create(:competition) }
  let(:template) { create(:certificates_template, competition:) }
  let(:preview) { described_class.new(template) }

  def image_type(data)
    return :png if data.start_with?("\x89PNG".b)

    :jpeg if data.byteslice(0, 2).bytes == [0xFF, 0xD8]
  end

  it 'renders the example certificate as image' do
    image = preview.image
    expect(image[:content_type]).to eq "image/#{image_type(image[:data])}"
    expect(Vips::Image.new_from_buffer(image[:data], '').width).to eq 827
  end

  it 'is cached until the template changes' do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Exports::Pdf::Certificates::Export).to receive(:perform).and_call_original

    described_class.new(template).image
    described_class.new(template).image
    expect(Exports::Pdf::Certificates::Export).to have_received(:perform).once

    create(:certificates_text_field, :free_text, template:)
    described_class.new(template.reload).image
    expect(Exports::Pdf::Certificates::Export).to have_received(:perform).twice
  end

  it 'falls back to mutool' do
    allow(ActiveStorage::Previewer::PopplerPDFPreviewer).to receive(:pdftoppm_exists?).and_return(false)
    expect(image_type(preview.image[:data])).to be_present
  end

  it 'raises when rendering fails' do
    allow(Open3).to receive(:capture2).and_return(['', instance_double(Process::Status, success?: false)])
    expect { preview.image }.to raise_error(/Urkunden-Vorschau fehlgeschlagen/)
  end
end
