# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team do
  let!(:competition) { create(:competition) }
  let!(:band) { create(:band, competition:) }
  let!(:la) { create(:discipline, :la, competition:) }
  let!(:assessment) { create(:assessment, competition:, discipline: la, band:) }
  let!(:user) { competition.users.first }

  describe 'teams managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/teams"
      expect(response).to match_html_fixture.with_affix('index-empty')

      get "/#{competition.year}/#{competition.slug}/teams/new?band_id=#{band.id}"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/teams",
           params: { band_id: band.id, team: { name: 'new-name', shortcut: '', number: '1' } }
      expect(response).to match_html_fixture.with_affix('new-with-errors').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/teams",
             params: { band_id: band.id, team: { name: 'new-name', shortcut: 'new-n', number: '1' } }
        follow_redirect!
        expect(response).to match_html_fixture.with_affix('show-empty')
      end.to change(described_class, :count).by(1)

      get "/#{competition.year}/#{competition.slug}/teams"
      expect(response).to match_html_fixture.with_affix('index-with-one')

      new_id = described_class.last.id

      get "/#{competition.year}/#{competition.slug}/teams/#{new_id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/teams/#{new_id}",
            params: { team: { name: 'new-name', shortcut: '', number: '1' } }
      expect(response).to have_http_status(:unprocessable_entity)

      patch "/#{competition.year}/#{competition.slug}/teams/#{new_id}",
            params: { team: { name: 'new-name', shortcut: 'short', number: '1' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams/#{new_id}")
      expect(described_class.find(new_id).shortcut).to eq('short')

      get "/#{competition.year}/#{competition.slug}/teams.pdf"
      expect(response).to match_pdf_fixture.with_affix('all-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="mannschaften.pdf"; ' \
        "filename*=UTF-8''mannschaften.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/teams.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="mannschaften.xlsx"; ' \
        "filename*=UTF-8''mannschaften.xlsx",
      )
      expect(response).to have_http_status(:success)

      expect do
        delete "/#{competition.year}/#{competition.slug}/teams/#{new_id}"
      end.to change(described_class, :count).by(-1)
    end
  end

  describe 'with fss team' do
    let!(:team) { create(:team, competition:, band:) }

    it 'shows team badge' do
      sign_in user
      get "/#{competition.year}/#{competition.slug}/teams"
      expect(response).to match_html_fixture.with_affix('with-warning')

      team.update!(fire_sport_statistics_team: create(:fire_sport_statistics_team, id: 1234))

      get "/#{competition.year}/#{competition.slug}/teams"
      expect(response).to match_html_fixture.with_affix('without-warning')
    end
  end

  describe 'people assessment requests' do
    let!(:team) { create(:team, competition:, band:) }
    let!(:hl) { create(:discipline, :hl, competition:) }
    let!(:hb) { create(:discipline, :hb, competition:) }
    let!(:fs) { create(:discipline, :fs, competition:) }
    let!(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
    let!(:assessment_hb) { create(:assessment, competition:, discipline: hb, band:) }
    let!(:assessment_fs) { create(:assessment, competition:, discipline: fs, band:) }

    it 'shows people table' do
      sign_in user
      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}"
      expect(response).to match_html_fixture.with_affix('with-empty-people-table')

      person = create(:person, competition:, band:, team:)
      create(:assessment_request, entity: person, assessment_type: :single_competitor, single_competitor_order: 2,
                                  assessment: assessment_hl)
      create(:assessment_request, entity: person, assessment_type: :group_competitor, group_competitor_order: 2,
                                  assessment: assessment_hb)
      create(:assessment_request, entity: person, assessment_type: :competitor, assessment:)

      person = create(:person, first_name: 'other', competition:, band:, team:)
      create(:assessment_request, entity: person, assessment_type: :out_of_competition, assessment: assessment_hl)
      create(:assessment_request, entity: person, assessment_type: :competitor, assessment: assessment_fs)

      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}"
      expect(response).to match_html_fixture.with_affix('with-people-table')
    end
  end

  describe 'assessment requests' do
    let!(:team) { create(:team, competition:, band:) }

    it 'can manage requests' do
      sign_in user

      tgl = create(:assessment, competition:, discipline: la, band:, forced_name: 'TGL')

      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}/edit_assessment_requests"
      expect(response).to match_html_fixture.with_affix('edit-assessment-requests')

      expect do
        patch "/#{competition.year}/#{competition.slug}/teams/#{team.id}?form=edit_assessment_requests",
              params: { team: { requests_attributes: {
                '0' => {
                  '_destroy' => '0',
                  'assessment_id' => assessment.id,
                  'assessment_type' => 'group_competitor',
                  'id' => assessment.requests.first.id,
                },
                '1' => {
                  '_destroy' => '0',
                  'assessment_id' => tgl.id,
                  'assessment_type' => 'out_of_competition',
                },
              } } }
      end.to change(AssessmentRequest, :count).by(1)

      get "/#{competition.year}/#{competition.slug}/teams/#{team.id}"
      expect(response).to match_html_fixture.with_affix('show-assessment-requests')

      patch "/#{competition.year}/#{competition.slug}/teams/#{team.id}?form=edit_assessment_requests",
            params: { team: { requests_attributes: {
              '0' => {
                '_destroy' => '0',
                'assessment_id' => assessment.id,
                'assessment_type' => 'group_competitor',
                'id' => assessment.requests.first.id,
              },
              '1' => {
                '_destroy' => '0',
                'assessment_id' => tgl.id,
                'assessment_type' => '',
              },
            } } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when user is a applicant' do
    let!(:other_user) { create(:user, :other, phone_number: '1234') }

    it 'uses CRUD' do
      competition.update!(registration_open_until: Date.current, registration_open: 'open', visible: true)

      sign_in other_user

      get "/#{competition.year}/#{competition.slug}/teams/new?band_id=#{band.id}"
      expect(response).to match_html_fixture.with_affix('new')

      expect do
        expect do
          post "/#{competition.year}/#{competition.slug}/teams",
               params: { band_id: band.id, team: { name: 'new-name', shortcut: 'new-n', number: '1' } }
          follow_redirect!
          expect(response).to match_html_fixture.with_affix('show-with-hint')
        end.to change(described_class, :count).by(1)
      end.to have_enqueued_job.with('CompetitionMailer', 'registration_team', 'deliver_now', any_args)
    end
  end

  context 'when firesport_statistics is not connected' do
    let!(:team) { create(:team, competition:, band:) }
    let!(:team_mv) { create(:team, competition:, band:, name: 'Mecklenburg-Vorpommern') }
    let!(:fss_team) { create(:fire_sport_statistics_team, id: 42) }

    it 'shows dialog' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/teams/without_statistics_connection"
      expect(response).to match_html_fixture.with_affix('list')

      patch "/#{competition.year}/#{competition.slug}/teams/#{team_mv.id}?return_to=without_statistics_connection",
            params: { team: { fire_sport_statistics_team_id: fss_team.id } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams/without_statistics_connection")

      expect(team_mv.reload.fire_sport_statistics_team_id).to eq fss_team.id

      team.destroy

      get "/#{competition.year}/#{competition.slug}/teams/without_statistics_connection"
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/teams")
    end
  end
end
