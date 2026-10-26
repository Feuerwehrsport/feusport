# frozen_string_literal: true

# Hintergrund-Dateien für Urkundenvorlagen, ohne Binär-Fixtures im Repo
module CertificateBackgrounds
  MARKER = 'FEUSPORT-HINTERGRUND'

  def background_pdf_upload(pages: 1, layout: :portrait)
    pdf = Prawn::Document.new(page_size: 'A4', page_layout: layout, margin: 0)
    pages.times do |i|
      pdf.start_new_page(layout:) if i.positive?
      pdf.add_content("% #{MARKER}")
      pdf.stroke_rectangle([10, 100], 50, 50)
    end
    background_upload(pdf.render, 'hintergrund.pdf', 'application/pdf')
  end

  def background_webp_upload
    background_upload(Vips::Image.black(20, 20).webpsave_buffer, 'hintergrund.webp', 'image/webp')
  end

  def background_upload(data, filename, content_type)
    file = Tempfile.new(['hintergrund', File.extname(filename)], binmode: true)
    file.write(data)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, true, original_filename: filename)
  end

  # Entpackte Inhaltsströme jeder Seite, um den Hintergrund-Marker zu finden
  def stamped_pages(data)
    CombinePDF.parse(data).pages.map do |page|
      contents = page[:Contents]
      (contents.is_a?(Array) ? contents : [contents]).map do |content|
        content = content[:referenced_object] || content
        raw = content[:raw_stream_content].to_s
        begin
          Zlib::Inflate.inflate(raw)
        rescue Zlib::Error
          raw
        end
      end.join
    end
  end
end

RSpec.configure { |config| config.include CertificateBackgrounds }
