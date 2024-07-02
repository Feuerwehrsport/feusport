# frozen_string_literal: true

Exports::Pdf::Certificates::Export = Struct.new(:template, :export_title, :rows, :background_image) do
  include Exports::Pdf::Base

  def perform
    pdf.font_families.update('certificates_template_regular' => { normal: font_path })
    pdf.font_families.update('certificates_template_bold' => { normal: font2_path })

    rows.each_with_index do |row, i|
      pdf.image(template.image_path, at: [0, height], width:, height:) if template.image.attached? && background_image
      template.text_fields.each { |position| render_position(position, row) }

      pdf.start_new_page if i != rows.count - 1
    end
  end

  protected

  def default_prawn_options
    super.merge(margin: [0, 0, 0, 0])
  end

  private

  def width
    @width ||= pdf.bounds.width
  end

  def height
    @height ||= pdf.bounds.height
  end

  def font_path
    template.font_path || Rails.root.join('app/assets/fonts/Arial.ttf')
  end

  def font2_path
    template.font2_path || Rails.root.join('app/assets/fonts/Arial_Bold.ttf')
  end

  def render_position(position, row)
    options = {
      at: [position.left, position.top],
      width: position.width,
      height: position.height,
      size: position.size,
      align: position.align,
      valign: :center,
    }
    pdf.fill_color position.color
    pdf.font("certificates_template_#{position.font}") do
      pdf.text_box(row.storage_support_get(position).to_s, options.merge(min_font_size: 4, overflow: :shrink_to_fit))
    end
  rescue Prawn::Errors::CannotFit
    pdf.font("certificates_template_#{position.font}") do
      pdf.text_box(row.storage_support_get(position).to_s, options.merge(size: 4, overflow: :truncate))
    end
  rescue Prawn::Errors::UnknownFont
    pdf.text_box(row.storage_support_get(position).to_s, options.merge(min_font_size: 4, overflow: :shrink_to_fit))
  end
end
