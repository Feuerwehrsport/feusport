# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home' do
  let!(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  before do
    view_sanitizer.gsub(%r{active_storage/blobs/redirect/[^/]+/}, 'BLOBID')
    view_sanitizer.gsub(%r{active_storage/representations/redirect/[^/]+/[^/]+/}, 'BLOBID')
  end

  describe 'home' do
    it 'shows home page' do
      get '/'
      expect(response).to match_html_fixture

      get "/?year=#{competition.year}"
      expect(response).to match_html_fixture.with_affix('only-year')

      create(:snapshot, highlight: true)
      get '/'
      expect(response).to match_html_fixture.with_affix('with-snapshot')
    end
  end

  describe 'info' do
    let!(:changelog) { Changelog.create!(date: Date.parse('2024-02-29'), title: 'Überschrift', md: "#hans\n\n- wurst") }

    it 'shows info page' do
      get '/info'
      expect(response).to match_html_fixture
    end
  end

  describe 'help' do
    it 'shows help page' do
      get '/help'
      expect(response).to match_html_fixture
    end
  end

  describe 'help_assessment' do
    it 'shows help assessment page' do
      get '/help_assessment'
      expect(response).to match_html_fixture
    end
  end

  describe 'changelogs' do
    let!(:changelog) { Changelog.create!(date: Date.parse('2024-02-29'), title: 'Überschrift', md: "#hans\n\n- wurst") }

    it 'shows changelogs page' do
      get '/changelogs'
      expect(response).to match_html_fixture
    end
  end

  describe 'disseminators' do
    it 'shows disseminators page' do
      Disseminator.create(name: 'Alfred Meier', lfv: 'Mecklenburg-Vorpommern', position: 'Chef',
                          email_address: 'foo@bar.de', phone_number: '0190 123456')
      get '/disseminators'
      expect(response).to match_html_fixture.with_affix('sign-in-hint')

      sign_in user

      get '/disseminators'
      expect(response).to match_html_fixture
    end
  end

  describe 'more' do
    it 'shows years of accessible competitions' do
      create(:competition, name: 'Alter Wettkampf', date: Date.parse('2019-05-01'))
      create(:competition, name: 'Versteckter Wettkampf', date: Date.parse('2015-05-01'), visible: false)

      get '/more'
      expect(response).to have_http_status(:success)
      expect(response.body).to include('href="/2024"', 'href="/2019"')
      expect(response.body).not_to include('href="/2015"')
      expect(response.body.index('href="/2024"')).to be < response.body.index('href="/2019"')
    end
  end
end
