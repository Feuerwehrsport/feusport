# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/score/monitors' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let(:la) { create(:discipline, :la, competition:) }
  let(:hl) { create(:discipline, :hl, competition:) }
  let(:male) { create(:band, :male, competition:) }
  let(:female) { create(:band, :female, competition:) }
  let(:assessment_la_male) { create(:assessment, competition:, discipline: la, band: male) }
  let(:assessment_la_female) { create(:assessment, competition:, discipline: la, band: female) }
  let(:assessment_hl) { create(:assessment, competition:, discipline: hl, band: male) }
  let(:result_la) { create(:score_result, competition:, assessment: assessment_la_male) }
  let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl) }

  let(:team_male) { create(:team, competition:, band: male, name: 'Mannschaft Männer') }
  let(:team_female) { create(:team, competition:, band: female, name: 'Mannschaft Frauen') }
  let(:person) do
    create(:person, competition:, band: male, team: team_male, first_name: 'Alfred', last_name: 'Meier',
                    bib_number: '123')
  end

  let!(:list_la) do
    create(:score_list, competition:, name: 'Löschangriff Lauf 1', results: [result_la],
                        assessments: [assessment_la_male, assessment_la_female]).tap do |list|
      create(:score_list_entry, list:, competition:, assessment: assessment_la_male, entity: team_male, run: 1,
                                track: 1, result_type: 'valid', time: 2345)
      create(:score_list_entry, list:, competition:, assessment: assessment_la_female, entity: team_female, run: 2,
                                track: 2)
    end
  end
  let!(:list_hl) do
    create(:score_list, competition:, name: 'Hakenleitersteigen Lauf 1', assessments: [assessment_hl],
                        results: [result_hl], track_count: 1).tap do |list|
      create(:score_list_entry, list:, competition:, assessment: assessment_hl, entity: person, run: 1, track: 1)
    end
  end

  let(:base) { "/#{competition.year}/#{competition.slug}/score/monitor" }

  it 'shows the monitor with the running list' do
    get base
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('score-monitor-toggle')
    expect(response.body).to include("#{base}/content")
    expect(response.body).to include('Hakenleitersteigen Lauf 1', 'Löschangriff Lauf 1')
    expect(response.body).not_to include('navbar')

    get "#{base}/content"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('<html')
    expect(response.body).to include("data-list-ids=\"#{list_la.id}\"")
    expect(response.body).to include('Mannschaft Männer', '23,45', 'Mannschaft Frauen', 'Jetzt')
    expect(response.body).to include('Löschangriff Nass - Frauen')
    expect(response.body).to include('Danach: Hakenleitersteigen Lauf 1', 'Alfred Meier')
  end

  it 'shows the selected lists' do
    competition.update!(show_bib_numbers: true)

    get "#{base}/content", params: { list_ids: [list_hl.id, list_la.id] }
    expect(response.body).to include("data-list-ids=\"#{list_hl.id},#{list_la.id}\"")
    expect(response.body).to include('score-monitor-count-2', 'Alfred Meier', '123', 'Mannschaft Männer')

    get "#{base}/content", params: { list_ids: list_hl.id }
    expect(response.body).to include("data-list-ids=\"#{list_la.id}\"")
  end

  it 'hides times and hidden lists also for admins' do
    sign_in user
    list_la.update!(hidden_results: true)

    get "#{base}/content"
    expect(response.body).to include('Mannschaft Männer')
    expect(response.body).not_to include('23,45')

    list_la.update!(hidden: true)
    get "#{base}/content"
    expect(response.body).not_to include('Mannschaft Männer')
    expect(response.body).to include('Alfred Meier')

    list_hl.update!(hidden: true)
    get "#{base}/content"
    expect(response.body).to include('Derzeit gibt es keine öffentliche Startliste.')
  end

  it 'needs read access to the competition' do
    competition.update!(visible: false)

    get base
    expect_access_denied

    sign_in user
    get base
    expect(response).to have_http_status(:ok)
  end

  it 'links from the list overview' do
    get "/#{competition.year}/#{competition.slug}/score/lists"
    expect(response.body).to include('Live-Anzeige', base)
  end
end
