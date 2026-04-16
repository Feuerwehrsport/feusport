# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    competition
    title { 'Ausschreibung' }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/doc.pdf')) }
  end
end
