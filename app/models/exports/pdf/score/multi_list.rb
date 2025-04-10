# frozen_string_literal: true

MULTI_LIST_HEADER_SIZE = 18
MULTI_LIST_LINE_HEIGHT = 11

PageColumn = Struct.new(:base, :pdf, :position) do
  def initialize(*)
    super
    if position == :left
      base.top_cursor = pdf.cursor
    else
      pdf.move_cursor_to base.top_cursor
    end
  end

  def fit?(list)
    pdf.cursor - MULTI_LIST_HEADER_SIZE - MULTI_LIST_LINE_HEIGHT - (MULTI_LIST_LINE_HEIGHT * list.track_count) > 0
  end

  def consume(list, from_run:, headline:, lines:)
    title(list) if from_run == 0

    remain_space = pdf.cursor - MULTI_LIST_LINE_HEIGHT
    needed_space_per_run = MULTI_LIST_LINE_HEIGHT * list.track_count

    runs_to_consume = (remain_space.to_i / needed_space_per_run.to_i)

    current_lines = lines[from_run * list.track_count, runs_to_consume * list.track_count]

    pdf.table([headline] + current_lines,
              position:,
              header: true,
              row_colors: base.pdf_row_colors(list),
              # width: pdf.bounds.width / 2 - 5, 256.64
              cell_style: { align: :center, size: 6, padding: [2, 2, 2, 2], border_widths: [0.5, 0.5, 0.5, 0.5] },

              column_widths: base.column_widths(list)) do
      row(0).style(font_style: :bold, border_widths: [0.5, 0.5, 1, 0.5], size: 5)
      line = 0
      loop do
        line += list.track_count
        break if line > row_length

        row(line).style(border_widths: [0.5, 0.5, 1, 0.5])
      end
    end

    pdf.move_down 10 if (runs_to_consume * list.track_count) + (from_run * list.track_count) >= lines.count

    from_run + runs_to_consume
  end

  def left(y = 0)
    (position == :left ? 0 : 270) + y
  end

  def title(list)
    current_y = pdf.cursor

    base.pdf_discipline_image(list.discipline.key, width: 12, at: [left(10), current_y])
    pdf.text_box(list.name, at: [left(25), current_y], size: 10, width: 200, height: 12, overflow: :shrink_to_fit,
                            valign: :center)
    pdf.move_down MULTI_LIST_HEADER_SIZE
  end
end

Exports::Pdf::Score::MultiList = Struct.new(:competition, :print_elements) do
  include Exports::Pdf::Base
  include Exports::ScoreLists

  attr_accessor :top_cursor

  def export_title
    'Startlisten'
  end

  def perform
    pdf_header('Startlisten')
    pdf.move_down 10
    @column = PageColumn.new(self, pdf, :left)
    print_elements.each do |element|
      case element
      when 'column'
        next_column
      when 'page'
        pdf.start_new_page
        @column = PageColumn.new(self, pdf, :left)
      when Score::List
        lines = show_export_data(element, pdf: true, show_bib_numbers: false, hint_size: 4,
                                          separate_target_times_as_columns: true)
        headline = lines.shift
        next_run = 0
        max_run = element.entries.maximum(:run) || 0
        while next_run < max_run
          next_column unless @column.fit?(element)

          next_run = @column.consume(element, from_run: next_run, headline:, lines:)
        end
      end
    end
    pdf_footer
  end

  def next_column
    if @column.position == :right
      pdf.start_new_page
      @column = PageColumn.new(self, pdf, :left)
    else
      @column = PageColumn.new(self, pdf, :right)
    end
  end

  def column_widths(list)
    # => 258
    if list.single_discipline?
      { 0 => 15, 1 => 16, 2 => 70, 3 => 60, 4 => 75, 5 => 22 }
    elsif list.separate_target_times?
      { 0 => 18, 1 => 18, 2 => 157, 3 => 20, 4 => 20, 5 => 25 }
    else
      { 0 => 18, 1 => 18, 2 => 197, 3 => 25 }
    end
  end

  def pdf_row_colors(list)
    color = 264
    (1..list.track_count).map do
      color -= 9
      color.to_s(16) * 3
    end
  end
end
