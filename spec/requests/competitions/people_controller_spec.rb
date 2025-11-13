# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'People' do
  let!(:competition) { create(:competition) }
  let!(:band) { create(:band, competition:) }
  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:assessment) { create(:assessment, competition:, discipline: hl, band:) }
  let!(:user) { competition.users.first }

  describe 'People managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/people"
      expect(response).to match_html_fixture.with_affix('index-empty')

      get "/#{competition.year}/#{competition.slug}/people/new?band_id=#{band.id}"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/people",
           params: { band_id: band.id,
                     person: { first_name: 'first-name', last_name: '', team_id: '', create_team_name: '' } }
      expect(response).to match_html_fixture.with_affix('new-with-errors').for_status(422)

      expect do
        expect do
          post "/#{competition.year}/#{competition.slug}/people",
               params: { band_id: band.id,
                         person: { first_name: 'first-name', last_name: 'last-name', team_id: '',
                                   create_team_name: 'new team' } }
          follow_redirect!
          expect(response).to match_html_fixture.with_affix('show')
        end.to change(Person, :count).by(1)
      end.to change(Team, :count).by(1)

      new_id = Person.last.id

      get "/#{competition.year}/#{competition.slug}/people"
      expect(response).to match_html_fixture.with_affix('index-with-one')

      get "/#{competition.year}/#{competition.slug}/people/#{new_id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/people/#{new_id}",
            params: { person: { first_name: '' } }
      expect(response).to have_http_status(:unprocessable_content)

      patch "/#{competition.year}/#{competition.slug}/people/#{new_id}",
            params: { person: { first_name: 'new-name' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/people/#{new_id}")
      expect(Person.find(new_id).first_name).to eq('new-name')

      get "/#{competition.year}/#{competition.slug}/people.pdf"
      expect(response).to match_pdf_fixture.with_affix('all-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="wettkampfer.pdf"; ' \
        "filename*=UTF-8''wettkampfer.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/people.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="wettkampfer.xlsx"; ' \
        "filename*=UTF-8''wettkampfer.xlsx",
      )
      expect(response).to have_http_status(:success)

      expect do
        delete "/#{competition.year}/#{competition.slug}/people/#{new_id}"
      end.to change(Person, :count).by(-1)
    end
  end

  describe 'return to team' do
    let(:team) { create(:team, competition:, band:) }
    let(:person) { create(:person, competition:, band:, team:) }

    it 'redirects to team page' do
      sign_in user

      patch "/#{competition.year}/#{competition.slug}/people/#{person.id}?return_to=team",
            params: { person: { first_name: 'new-name' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams/#{team.id}?jump_to=people-table")

      post "/#{competition.year}/#{competition.slug}/people?return_to=team",
           params: { band_id: band.id,
                     person: { first_name: 'first-name', last_name: 'last-name', team_id: team.id } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams/#{team.id}?jump_to=people-table")
    end
  end

  context 'when user is a applicant' do
    let!(:other_user) { create(:user, :other, phone_number: '1234') }

    it 'uses CRUD' do
      competition.update!(registration_open_until: Date.current, registration_open: 'open', visible: true)

      sign_in other_user

      get "/#{competition.year}/#{competition.slug}/people/new?band_id=#{band.id}"
      expect(response).to match_html_fixture.with_affix('new')

      expect do
        expect do
          post "/#{competition.year}/#{competition.slug}/people",
               params: { band_id: band.id,
                         person: { first_name: 'first-name', last_name: 'last-name', team_id: '',
                                   create_team_name: 'new team' } }
          follow_redirect!
          expect(response).to match_html_fixture.with_affix('show-with-hint')
        end.to change(Person, :count).by(1)
      end.to have_enqueued_job.with('CompetitionMailer', 'registration_person', 'deliver_now', any_args)
    end
  end

  context 'when firesport_statistics is not connected' do
    let!(:person) { create(:person, competition:, band:) }
    let!(:person_peter) { create(:person, competition:, band:, first_name: 'Peter') }
    let!(:fss_person) { create(:fire_sport_statistics_person, id: 42) }

    it 'shows dialog' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/people/without_statistics_connection"
      expect(response).to match_html_fixture.with_affix('list')

      patch "/#{competition.year}/#{competition.slug}/people/#{person.id}?return_to=without_statistics_connection",
            params: { person: { fire_sport_statistics_person_id: fss_person.id } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/people/without_statistics_connection")

      expect(person.reload.fire_sport_statistics_person_id).to eq fss_person.id

      person_peter.destroy

      get "/#{competition.year}/#{competition.slug}/people/without_statistics_connection"
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/people")
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('without-warning')
    end
  end

  context 'when xhr to edit_assessment_requests' do
    let!(:person) { create(:person, competition:, band:) }

    it 'shows dialog' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/people/#{person.id}/edit_assessment_requests",
          headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      expect(response).to have_http_status(:success)

      json = response.parsed_body
      expect(json['content'].length).to be > 3500
      expect(json['content'].length).to be < 4000

      get "/#{competition.year}/#{competition.slug}/people/#{person.id}/edit_assessment_requests?assessment_id=foo",
          headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      expect(response).to have_http_status(:success)

      json = response.parsed_body
      expect(json['content'].length).to be < 1000
    end
  end
end
