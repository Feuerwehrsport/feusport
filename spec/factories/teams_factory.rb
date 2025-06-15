# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    competition
    band

    name { "#{band.name}-Team" }
    sequence(:number) { |n| n }
    shortcut { "#{band.name}-T" }
  end

  factory :team_marker do
    competition
    name { 'Angereist?' }
    value_type { 'boolean' }

    trait :date do
      name { 'Bezahlt?' }
      value_type { 'date' }
    end

    trait :string do
      name { 'Wünsche?' }
      value_type { 'string' }
    end
  end
end
