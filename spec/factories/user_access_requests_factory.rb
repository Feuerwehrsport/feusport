# frozen_string_literal: true

FactoryBot.define do
  factory :user_access_request do
    competition
    sender { User.first || association(:user) }
    email { 'access@request.de' }
    text {  "Hallo\nwillst du?" }
  end

  factory :user_team_access_request do
    competition
    team { association :team, competition: }
    sender { User.first || association(:user) }
    email { 'access@request.de' }
    text {  "Hallo\nwillst du?" }
  end
end
