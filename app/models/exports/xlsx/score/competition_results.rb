# frozen_string_literal: true

Exports::Xlsx::Score::CompetitionResults = Struct.new(:competition, :results) do
  include Exports::Xlsx::Base
  include Exports::CompetitionResults

  def perform
    results.each do |result|
      add_worksheet(result.name) do |sheet|
        table_data(result).each { |row| sheet.add_row(row) }
      end
    end
  end
end
