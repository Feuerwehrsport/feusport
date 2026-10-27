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

  describe 'filter' do
    let(:din) { create(:feature, :din) }
    let(:tgl) { create(:feature, :tgl) }
    let!(:old_published) do
      create(:competition, name: 'Alt-Cup', date: 2.months.from_now.to_date, features: [din],
                           published_at: 1.day.ago, lat: '54.08', lng: '12.13')
    end
    let!(:new_published) do
      create(:competition, name: 'Neu-Cup', date: 1.month.from_now.to_date, features: [tgl],
                           published_at: 2.days.ago, lat: '52.52', lng: '13.40')
    end

    before { competition.update!(published_at: 1.month.ago) }

    def names
      response.body.scan(/<h6 class="mb-0">\s*([^<]+?)\s*</).flatten
    end

    it 'filters and sorts competitions' do
      get '/'
      expect(names).to eq %w[MV-Cup Neu-Cup Alt-Cup]
      expect(response.body.scan('badge text-bg-success').count).to eq 2
      expect(response.body).not_to include('name="distance"')
      expect(response.body).to include('btn btn-sm btn-outline-secondary')
      expect(response.body).not_to include('btn btn-sm btn-primary active')

      get '/', params: { sort: 'published' }
      expect(names).to eq %w[Alt-Cup Neu-Cup MV-Cup]
      expect(response.body).to include('Neu veröffentlicht', 'veröffentlicht am 29.01.2024',
                                       'veröffentlicht am 28.02.2024')
      expect(response.body).to include("href=\"/#{Date.current.year}?sort=published\"")

      get '/', params: { feature_ids: [din.id] }
      expect(names).to eq %w[Alt-Cup]
      expect(response.body).to include('btn btn-sm btn-primary active')
      expect(response.body).to include('Zurücksetzen')

      get '/', params: { feature_ids: [din.id], distance: 50 }
      expect(names).to eq %w[Alt-Cup]

      get '/', params: { feature_ids: [tgl.id], sort: 'published' }
      expect(names).to eq %w[Neu-Cup]

      get '/', params: { feature_ids: [create(:feature, name: 'Leer').id] }
      expect(names).to eq []
      expect(response.body).to include('Keine Wettkämpfe gefunden')
    end

    it 'uses distance and interests of signed in user' do
      user = User.first
      user.update!(features: [tgl], lat: '54.1', lng: '12.1', distance: 300)
      sign_in user

      get '/', params: { distance: 50 }
      expect(names).to eq %w[Alt-Cup]
      expect(response.body).to include('name="distance"', 'Meine Interessen')
      expect(response.body).to include("href=\"/?distance=300&amp;feature_ids%5B%5D=#{tgl.id}\"")
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
