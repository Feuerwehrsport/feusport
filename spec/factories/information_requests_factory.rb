# frozen_string_literal: true

FactoryBot.define do
  factory :information_request do
    competition
    user { User.first || association(:user) }
    message { "Hallo\nIch will Infos!\n Tschüssssi" }
  end
end
