# frozen_string_literal: true

# == Schema Information
#
# Table name: competitions
#
#  id                      :uuid             not null, primary key
#  change_people_until     :date
#  date                    :date             not null
#  description             :text
#  flyer_content           :text
#  flyer_headline          :string
#  locked_at               :datetime
#  lottery_numbers         :boolean          default(FALSE), not null
#  name                    :string(50)       not null
#  place                   :string(50)       not null
#  preset_ran              :boolean          default(FALSE), not null
#  registration_open       :integer          default("unstated"), not null
#  registration_open_until :date
#  show_bib_numbers        :boolean          default(FALSE), not null
#  slug                    :string(50)       not null
#  visible                 :boolean          default(FALSE), not null
#  year                    :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  wko_id                  :uuid
#
# Indexes
#
#  index_competitions_on_date           (date)
#  index_competitions_on_wko_id         (wko_id)
#  index_competitions_on_year_and_slug  (year,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (wko_id => wkos.id)
#
require 'rails_helper'

RSpec.describe Competition do
  let(:competition) { create(:competition) }

  describe 'auto registration_open_until' do
    it 'changes automaticly' do
      expect(competition.registration_open_until).to eq Date.parse('2024-02-28')

      competition.update!(date: Date.parse('2024-02-02'))
      expect(competition.registration_open_until).to eq Date.parse('2024-02-01')

      competition.update!(date: Date.parse('2024-02-10'))
      expect(competition.registration_open_until).to eq Date.parse('2024-02-01')
    end
  end
end
