# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompetitionMailer do
  describe 'access_request' do
    let(:access_request) { create(:user_access_request) }
    let(:mail) { described_class.with(access_request:).access_request }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Zugangsanfrage für Wettkampf - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'access@request.de'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail).to match_html_fixture
    end
  end

  describe 'access_request_connected' do
    let(:user) { create(:user) }
    let(:sender) { create(:user, :other) }
    let(:competition) { create(:competition) }
    let(:mail) { described_class.with(sender:, user:, competition:).access_request_connected }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Zugangsanfrage für Wettkampf verbunden - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'Other Meier <other@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq ''
      expect(mail).to match_html_fixture
    end
  end

  describe 'user_team_access_request' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, competition:) }
    let(:team) { create(:team, competition:, band:) }
    let(:user_team_access_request) { create(:user_team_access_request, competition:, team:) }
    let(:mail) { described_class.with(user_team_access_request:).user_team_access_request }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Verwalteranfrage für Mannschaft - MV-Cup / Frauen-Team')
      expect(mail.header[:to].to_s).to eq 'access@request.de'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail).to match_html_fixture
    end
  end

  describe 'user_team_access_request_connected' do
    let(:user) { create(:user) }
    let(:sender) { create(:user, :other) }
    let(:competition) { create(:competition) }
    let(:band) { create(:band, competition:) }
    let(:team) { create(:team, competition:, band:) }
    let(:mail) { described_class.with(sender:, user:, competition:, team:).user_team_access_request_connected }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Verwalteranfrage für Mannschaft verbunden - MV-Cup / Frauen-Team')
      expect(mail.header[:to].to_s).to eq 'Other Meier <other@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq ''
      expect(mail).to match_html_fixture
    end
  end

  describe 'registration_team' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, competition:) }
    let(:user) { create(:user, :other) }
    let(:user_team_access) { UserTeamAccess.new(user:, competition:) }
    let(:team) do
      create(:team, competition:, band:, user_team_accesses: [user_team_access], registration_hint: "foo\nbar")
    end
    let(:mail) { described_class.with(team:).registration_team }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Neue Wettkampfanmeldung - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq ''
      expect(mail).to match_html_fixture
    end
  end

  describe 'registration_person' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, competition:) }
    let(:user) { create(:user, :other) }
    let(:user_person_access) { UserPersonAccess.new(user:, competition:) }
    let(:person) do
      create(:person, competition:, band:, user_person_accesses: [user_person_access], registration_hint: "foo\nbar")
    end
    let(:mail) { described_class.with(person:).registration_person }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Neue Wettkampfanmeldung - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq ''
      expect(mail).to match_html_fixture
    end
  end

  describe 'publishing_reminder' do
    let(:competition) { create(:competition) }
    let(:mail) { described_class.with(competition:).publishing_reminder }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Übertrage die Ergebnisse deines Wettkampfs - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq ''
      expect(mail).to match_html_fixture
    end
  end

  describe 'information_request' do
    let(:information_request) { create(:information_request) }
    let(:mail) { described_class.with(information_request:).information_request }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Informationsanfrage zu deinem Wettkampf - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail).to match_html_fixture
    end
  end

  describe 'access_deleted' do
    let(:competition) { create(:competition) }
    let(:actor) { competition.users.first }
    let(:user) { create(:user, :other) }
    let(:mail) { described_class.with(competition:, user:, actor:).access_deleted }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Zugang zum Wettkampf entfernt - MV-Cup')
      expect(mail.header[:to].to_s).to eq 'Other Meier <other@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail.header[:reply_to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail).to match_html_fixture
    end
  end

  describe 'user_team_access_deleted' do
    let(:competition) { create(:competition) }
    let(:band) { create(:band, competition:) }
    let(:team) { create(:team, competition:, band:) }
    let(:actor) { competition.users.first }
    let(:user) { create(:user, :other) }
    let(:mail) { described_class.with(competition:, user:, actor:, team:).user_team_access_deleted }

    it 'renders the headers and body' do
      expect(mail.subject).to eq('Zugang zur Mannschaft entfernt - MV-Cup / Frauen-Team')
      expect(mail.header[:to].to_s).to eq 'Other Meier <other@meier.de>'
      expect(mail.header[:from].to_s).to eq 'Feuerwehrsport <no-reply@feusport.de>'
      expect(mail.header[:cc].to_s).to eq ''
      expect(mail.header[:reply_to].to_s).to eq 'Alfred Meier <alfred@meier.de>'
      expect(mail).to match_html_fixture
    end
  end
end
