# frozen_string_literal: true

FactoryBot.define do
  factory :series_round, class: 'Series::Round' do
    name { 'D-Cup' }
    year { Date.current.year }

    trait :with_team_config do
      team_assessments_config_jsonb do
        [
          {
            'key' => 'male-la',
            'name' => 'LA-Männer',
            'disciplines' => ['la'],
            'calc_participations_count' => 1,
            'ranking_logic' => ['points'],
          },
        ]
      end
    end

    trait :with_person_config do
      person_assessments_config_jsonb do
        [
          {
            'key' => 'male-hl',
            'name' => 'HL-Männer',
            'disciplines' => ['hl'],
            'calc_participations_count' => 1,
            'ranking_logic' => ['points'],
          },
        ]
      end
    end
  end
end
