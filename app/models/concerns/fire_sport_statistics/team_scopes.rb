# frozen_string_literal: true

module FireSportStatistics::TeamScopes
  extend ActiveSupport::Concern

  included do
    scope :like_name_or_short, ->(name) do
      name = "%#{name.chars.map { |char| sanitize_sql_like(char) }.join('%')}%"
      name_match = arel_table[:name].matches(name)
      short_match = arel_table[:short].matches(name)
      where(name_match.or(short_match))
    end
  end
end
