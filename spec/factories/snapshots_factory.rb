# frozen_string_literal: true

FactoryBot.define do
  factory :snapshot do
    competition
    title { 'Bild vom Wettkampf' }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/pixel.jpg')) }

    trait :large_image do
      file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/large_image.jpg')) }
    end
  end
end
