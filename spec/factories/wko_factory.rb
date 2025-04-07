# frozen_string_literal: true

# == Schema Information
#
# Table name: wkos
#
#  id             :uuid             not null, primary key
#  description_md :text             not null
#  name           :string(100)      not null
#  slug           :string(100)      not null
#  subtitle       :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_wkos_on_slug  (slug) UNIQUE
#
FactoryBot.define do
  factory :wko do
    slug { '2023' }
    name { 'WKO 2023' }
    subtitle { 'DFV-Wettkampfordnung - 4. Auflage 2023' }
    description_md { "**Wichtig**\n\nEs folgt *nichts*" }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/doc.pdf')) }
  end
end
