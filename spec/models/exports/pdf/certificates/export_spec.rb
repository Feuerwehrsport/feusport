# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Pdf::Certificates::Export do
  let(:competition) { create(:competition) }
  let(:template) { create(:certificates_template, competition:) }
  let(:row) { instance_double(Score::ResultRow) }
  let(:text_options) { [] }

  before do
    allow(row).to receive(:storage_support_get) { |position| "Text #{position.key}" }
  end

  def capture_text_boxes(export)
    allow(export.pdf).to receive(:text_box).and_wrap_original do |original, text, options|
      text_options.push([text, options])
      original.call(text, options)
    end
  end

  def perform(export)
    export.unicode_perform
    export
  end

  it 'renders the background image with full page size when requested' do
    create(:certificates_text_field, :free_text, template:)
    export = described_class.new(template.reload, 'Urkunden', [row, row], true)
    allow(export.pdf).to receive(:image).and_call_original
    perform(export)

    expect(export.pdf).to have_received(:image).twice.with(
      template.image_path, at: [0, export.pdf.bounds.height], width: export.pdf.bounds.width,
                           height: export.pdf.bounds.height
    )
    expect(export.pdf.page_count).to eq 2
  end

  it 'does not render the background image when disabled' do
    create(:certificates_text_field, :free_text, template:)
    export = described_class.new(template.reload, 'Urkunden', [row], false)
    allow(export.pdf).to receive(:image).and_call_original
    perform(export)

    expect(export.pdf).not_to have_received(:image)
    expect(export.pdf.page_count).to eq 1
  end

  it 'falls back to truncated small text when text cannot fit' do
    create(:certificates_text_field, :free_text, template:, width: 4)
    export = described_class.new(template.reload, 'Urkunden', [row], false)
    capture_text_boxes(export)
    perform(export)

    expect(text_options.map(&:first)).to eq ['Text text', 'Text text']
    expect(text_options.first.last).to include(min_font_size: 4, overflow: :shrink_to_fit)
    expect(text_options.last.last).to include(size: 4, overflow: :truncate)
  end

  it 'uses current font when font of text field is unknown' do
    create(:certificates_text_field, :free_text, template:, font: 'unknown')
    export = described_class.new(template.reload, 'Urkunden', [row], false)
    capture_text_boxes(export)
    perform(export)

    expect(text_options.map(&:first)).to eq ['Text text']
    expect(text_options.last.last).to include(min_font_size: 4, overflow: :shrink_to_fit)
    expect(export.bytestream).to start_with('%PDF')
  end
end
