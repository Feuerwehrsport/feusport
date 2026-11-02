# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/circular_mails' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, :female, competition:) }
  let(:team) { create(:team, competition:, band:) }
  let(:person) { create(:person, :generated, competition:, band:) }
  let(:other_user) { create(:user, :other) }

  it 'sends a circular mail' do
    sign_in user

    get competition_nested('circular_mails/new')
    expect(response).to match_html_fixture.with_affix('new-without-recipients')

    post competition_nested('circular_mails'), params: { circular_mail: { subject: 'Infos', message: 'Text' } }
    expect(response).to match_html_fixture.with_affix('new-without-recipients-error').for_status(422)

    UserTeamAccess.create!(user: other_user, competition:, team:)
    UserPersonAccess.create!(user: other_user, competition:, person:)
    UserPersonAccess.create!(user:, competition:, person:)

    get competition_nested('circular_mails/new')
    expect(response).to match_html_fixture.with_affix('new')

    post competition_nested('circular_mails'), params: { circular_mail: { subject: '', message: '' } }
    expect(response).to have_http_status(:unprocessable_content)

    expect do
      post competition_nested('circular_mails'), params: { circular_mail: { subject: 'Infos', message: 'Text' } }
      expect(response).to redirect_to(competition_nested)
      follow_redirect!
      expect(response.body).to include('Die Rundmail wird an 2 Empfänger verschickt.')
    end.to have_enqueued_job.with('CompetitionMailer', 'circular_mail', 'deliver_now', any_args)

    mail = CircularMail.last
    expect(mail).to have_attributes(subject: 'Infos', message: 'Text', user:, recipients_count: 2)
  end

  it 'works for locked competitions' do
    UserTeamAccess.create!(user: other_user, competition:, team:)
    competition.update!(locked_at: Time.current)
    sign_in user

    get competition_nested
    expect(response.body).to include('Rundmail an Anmeldungen')

    get competition_nested('circular_mails/new')
    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('alert-danger')

    expect do
      post competition_nested('circular_mails'), params: { circular_mail: { subject: 'Infos', message: 'Text' } }
      expect(response).to redirect_to(competition_nested)
    end.to have_enqueued_job.with('CompetitionMailer', 'circular_mail', 'deliver_now', any_args)
  end

  it 'shows the link only to admins' do
    sign_in user
    get competition_nested
    expect(response.body).to include('Rundmail an Anmeldungen')

    sign_in other_user
    get competition_nested
    expect(response.body).not_to include('Rundmail an Anmeldungen')
  end

  it 'denies access to others' do
    get competition_nested('circular_mails/new')
    expect_access_denied

    sign_in other_user
    get competition_nested('circular_mails/new')
    expect(response).to redirect_to('/')
    expect(flash[:alert]).to eq 'Zugriff verweigert'
    expect do
      post competition_nested('circular_mails'), params: { circular_mail: { subject: 'Infos', message: 'Text' } }
      expect(response).to redirect_to('/')
    end.not_to change(CircularMail, :count)
  end
end
