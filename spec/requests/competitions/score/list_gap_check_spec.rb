# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/score/lists gap check' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, competition:) }
  let!(:assessment) { create(:assessment, competition:, band:) }
  let(:people) { Array.new(2) { create(:person, :generated, competition:, band:) } }
  let(:first_list) { create(:score_list, competition:, name: 'HL', track_count: 1) }
  let(:second_list) { create(:score_list, competition:, name: 'HB', track_count: 1) }

  before do
    [[first_list, people], [second_list, people.reverse]].each do |list, entities|
      entities.each_with_index do |entity, index|
        create(:score_list_entry, competition:, list:, entity:, run: index + 1, track: 1)
      end
    end
  end

  it 'shows a hint on the list and move page' do
    sign_in user

    get competition_nested("score/lists/#{second_list.id}")
    expect(response.body).to include('Wenig Pause zu anderen Startlisten')
    expect(response.body).to include("score/lists/#{first_list.id}")
    expect(response.body).to include('Am Ende: Lauf 2')

    first_list.update!(starting_time: Time.zone.local(2024, 2, 29, 9))
    second_list.update!(starting_time: Time.zone.local(2024, 2, 29, 11))
    get competition_nested("score/lists/#{first_list.id}")
    expect(response.body).to include('Am Anfang: Lauf 1')

    get competition_nested("score/lists/#{second_list.id}/move")
    expect(response.body).to include('Wenig Pause zu anderen Startlisten')

    second_list.update!(date: Date.new(2024, 3, 1))
    first_list.update!(date: Date.new(2024, 2, 29))
    get competition_nested("score/lists/#{second_list.id}")
    expect(response.body).not_to include('Wenig Pause zu anderen Startlisten')
  end
end
