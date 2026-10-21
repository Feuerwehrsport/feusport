# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Hidden lists in results' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:band) { create(:band, competition:) }
  let(:assessment) { create(:assessment, competition:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }

  let(:public_person) { create(:person, competition:, band:, first_name: 'Offen', last_name: 'Sichtbar') }
  let(:hidden_person) { create(:person, competition:, band:, first_name: 'Geheim', last_name: 'Versteckt') }

  let!(:public_list) { create_score_list(result, { public_person => 2000 }, 'Lauf 1') }
  let!(:hidden_list) do
    create_score_list(result, { hidden_person => 1500 }, 'Lauf 2').tap do |list|
      list.update!(shortcut: 'Geheim', hidden_results: true)
    end
  end

  describe 'result page' do
    it 'shows hidden lists only to admins' do
      get competition_nested("score/results/#{result.id}")
      expect(response.body).to include('Sichtbar')
      expect(response.body).not_to include('Versteckt')
      expect(response.body).not_to include('>Geheim')
      expect(response.body).not_to include('Versteckte Startlisten')
      expect(response.body).not_to include('Lauf 2')

      sign_in user
      get competition_nested("score/results/#{result.id}")
      expect(response.body).to include('Versteckt')
      expect(response.body).to include('Geheim <i class="far fa-eye-slash" title="Nicht öffentlich"></i>')
      expect(response.body).to include('Versteckte Startlisten')
    end

    it 'exports hidden lists only for admins' do
      expect(Exports::Xlsx::Score::Result).to receive(:perform).twice.and_wrap_original do |original, exported|
        exported_names = exported.rows.map { |row| row.entity.last_name }
        expect(exported_names).to eq(exported.include_hidden_lists ? %w[Versteckt Sichtbar] : ['Sichtbar'])
        original.call(exported)
      end

      get competition_nested("score/results/#{result.id}.xlsx")
      sign_in user
      get competition_nested("score/results/#{result.id}.xlsx")
    end
  end

  describe 'competition results' do
    let!(:visible) { create(:score_competition_result, competition:, name: 'Offen', results: [result]) }
    let!(:hidden) { create(:score_competition_result, competition:, name: 'Intern', hidden: true, results: [result]) }

    it 'exports hidden competition results only for admins' do
      expect(Exports::Xlsx::Score::CompetitionResults).to receive(:perform)
        .with(competition, [visible]).and_call_original
      get competition_nested('score/competition_results.xlsx')

      get competition_nested("score/competition_results/#{hidden.id}.xlsx")
      expect(response).to redirect_to(competition_nested('score/competition_results'))

      sign_in user
      expect(Exports::Xlsx::Score::CompetitionResults).to receive(:perform)
        .with(competition, contain_exactly(visible, hidden)).and_call_original
      get competition_nested('score/competition_results.xlsx')
      expect(response).to have_http_status(:success)

      get competition_nested('score/competition_results')
      expect(response.body).to include('Versteckte Startlisten')
    end
  end

  describe 'list exports' do
    it 'hides times of hidden results for visitors' do
      expect(Exports::Xlsx::Score::List).to receive(:perform).with(hidden_list, true).and_call_original
      get competition_nested("score/lists/#{hidden_list.id}.xlsx")
      expect(response).to have_http_status(:success)

      sign_in user
      expect(Exports::Xlsx::Score::List).to receive(:perform).with(hidden_list, false).and_call_original
      get competition_nested("score/lists/#{hidden_list.id}.xlsx")
    end

    it 'does not export hidden lists for visitors' do
      hidden_list.update!(hidden: true)

      get competition_nested("score/lists/#{hidden_list.id}.pdf")
      expect(response).to redirect_to(competition_nested("score/lists/#{hidden_list.id}"))

      sign_in user
      get competition_nested("score/lists/#{hidden_list.id}.pdf")
      expect(response.content_type).to eq(Mime[:pdf])
    end
  end

  describe 'admin notices' do
    before { sign_in user }

    it 'marks lists with hidden results in the overview' do
      get competition_nested('score/lists')
      expect(response.body).to include('<i class="far fa-eye-low-vision" title="Öffentlich, Ergebnisse versteckt"></i>')

      hidden_list.update!(hidden: true)
      get competition_nested('score/lists')
      expect(response.body).not_to include('fa-eye-low-vision')
      expect(response.body).to include('<i class="far fa-eye-slash" title="Nicht öffentlich"></i>')
    end

    it 'warns on publishing and certificates' do
      get competition_nested('publishing/new')
      expect(response.body).to include('Ihre Ergebnisse werden nicht übertragen')
      expect(response.body).to include('Lauf 2')

      get competition_nested('certificates/lists/new')
      expect(response.body).to include('Urkunden enthalten ihre Einträge trotzdem')
    end
  end
end
