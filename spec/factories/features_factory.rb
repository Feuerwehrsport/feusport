# frozen_string_literal: true

FactoryBot.define do
  factory :feature do
    name { 'DIN' }

    trait :din

    trait :tgl do
      name { 'TGL' }
    end
  end
end
