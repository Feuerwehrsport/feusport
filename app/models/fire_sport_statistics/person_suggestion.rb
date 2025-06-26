# frozen_string_literal: true

FireSportStatistics::PersonSuggestion = Struct.new(:person) do
  delegate :count, :any?, :first, :present?, to: :suggestions

  def suggestions
    @suggestions ||= FireSportStatistics::Person.for_person(person)
  end
end
