# frozen_string_literal: true

FactoryBot.define do
  sequence(:first_name) { |n| "Alfred#{n}" }
  sequence(:last_name) { |n| "Meier#{n}" }

  factory :person do
    competition

    first_name { 'Alfred' }
    last_name { 'Meier' }
    band { Band.find_by(gender: :male, competition:) || build(:band, :male, competition:) }

    trait :generated do
      first_name { generate(:first_name) }
      last_name { generate(:last_name) }
    end

    trait :male
    trait :female do
      band { Band.find_by(gender: :female, competition:) || build(:band, :female, competition:) }
    end
    trait :with_team do
      team do |person|
        Team.find_by(band: person.band, competition: person.competition) ||
          build(:team, band: person.band, competition:)
      end
    end
  end
end
