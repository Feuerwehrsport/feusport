# frozen_string_literal: true

Exports::Xlsx::Score::List = Struct.new(:list) do
  include Exports::Xlsx::Base
  include Exports::ScoreLists

  delegate :competition, to: :list

  def perform
    add_worksheet(export_title) do |sheet|
      show_export_data(list).each { |row| sheet.add_row(row) }
    end
  end
end
