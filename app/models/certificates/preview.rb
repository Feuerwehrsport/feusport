# frozen_string_literal: true

require 'open3'

class Certificates::Preview
  DPI = 100

  attr_reader :template

  def initialize(template)
    @template = template
  end

  def cache_key
    [template.cache_key_with_version, *%i[image font font2].map { |file| template.public_send(file).blob&.checksum }]
  end

  # { data:, content_type: }
  def image
    Rails.cache.fetch(['certificates/preview', *cache_key], expires_in: 2.weeks) { render }
  end

  private

  def render
    pdf = Exports::Pdf::Certificates::Export.perform(template, template.name, [Certificates::Example.new], true)
    image = Vips::Image.pngload_buffer(rasterize(pdf.bytestream))
    image = image.flatten(background: 255) if image.has_alpha?

    jpg = image.jpegsave_buffer(Q: 85)
    png = image.pngsave_buffer(compression: 9)
    jpg.bytesize < png.bytesize ? { data: jpg, content_type: 'image/jpeg' } : { data: png, content_type: 'image/png' }
  end

  def rasterize(pdf_data)
    Tempfile.create(['urkunde', '.pdf'], binmode: true) do |file|
      file.write(pdf_data)
      file.flush
      png, status = Open3.capture2(*rasterize_command(file.path), binmode: true)
      raise "Urkunden-Vorschau fehlgeschlagen (#{rasterize_command(file.path).first})" unless status.success?

      png
    end
  end

  def rasterize_command(path)
    if ActiveStorage::Previewer::PopplerPDFPreviewer.pdftoppm_exists?
      [ActiveStorage::Previewer::PopplerPDFPreviewer.pdftoppm_path, '-singlefile', '-cropbox', '-r', DPI.to_s,
       '-png', path]
    else
      [ActiveStorage::Previewer::MuPDFPreviewer.mutool_path, 'draw', '-F', 'png', '-o', '-', '-r', DPI.to_s, path, '1']
    end
  end
end
