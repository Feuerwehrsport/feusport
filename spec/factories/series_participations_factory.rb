# frozen_string_literal: true

FactoryBot.define do
  factory :series_person_participation, class: 'Series::PersonParticipation' do
    cup { Series::Cup.first || build(:series_cup) }
    person { FireSportStatistics::Person.first || build(:fire_sport_statistics_person) }
    time { 1899 }
    points { 15 }
    rank { 2 }
  end

  factory :series_team_participation, class: 'Series::TeamParticipation' do
    cup { Series::Cup.first || build(:series_cup) }
    team { FireSportStatistics::Team.first || build(:fire_sport_statistics_team) }
    team_number { 1 }
    time { 1899 }
    points { 15 }
    rank { 2 }
  end
end
