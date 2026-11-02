# frozen_string_literal: true

FactoryBot.define do
  factory :circular_mail do
    competition
    user { User.first || association(:user) }
    subject { 'Wichtige Infos' }
    message { "Hallo zusammen,\n\n- Anreise ab **8 Uhr**\n- Parkplatz am Sportplatz" }
  end
end
