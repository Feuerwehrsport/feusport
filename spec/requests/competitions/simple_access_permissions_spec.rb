# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/simple_access permissions' do
  let(:competition) { create(:competition) }

  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment) { create(:assessment, competition:, discipline: hl, band: female) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:person1) { create(:person, :generated, competition:, band: female) }
  let(:person2) { create(:person, :generated, competition:, band: female) }

  let!(:list) { create_score_list(result, { person1 => :waiting }, 'Lauf A') }
  let!(:hidden_list) do
    create_score_list(result, { person2 => :waiting }, 'Lauf B').tap do |l|
      l.update!(hidden: true)
    end
  end

  def login(permission, score_lists = [])
    SimpleAccess.create!(competition:, name: 'Zeitnehmer', password: 'secret123', permission:,
                         score_list_ids: score_lists.map(&:id))
    post competition_nested('simple_access_login'),
         params: { simple_access_login: { name: 'Zeitnehmer', password: 'secret123' } }
  end

  def edit_run(list)
    get competition_nested("score/lists/#{list.id}/runs/1/edit")
  end

  def update_run(list, time)
    patch competition_nested("score/lists/#{list.id}/runs/1"),
          params: { score_run: { list_entries_attributes: { '0' => {
            'track' => '1', 'edit_second_time' => time, 'edit_second_time_before' => '',
            'result_type_before' => 'waiting', 'result_type' => 'valid'
          } } } }
  end

  context 'with permission results' do
    before { login(:results) }

    it 'allows times only for not hidden lists' do
      edit_run(list)
      expect(response).to have_http_status(:success)
      update_run(list, '22.34')
      expect(list.entries.first.reload.time).to eq 2234

      get competition_nested("score/lists/#{list.id}")
      expect(response.body).to include('Zeiten bearbeiten')
      expect(response.body).not_to include('Reihenfolge bearbeiten')

      edit_run(hidden_list)
      expect_access_denied
      update_run(hidden_list, '22.34')
      expect_access_denied
      expect(hidden_list.entries.first.reload.time).to be_nil

      get competition_nested("score/lists/#{hidden_list.id}")
      expect(response.body).to include('Diese Startliste ist derzeit nicht öffentlich einsehbar.')
      get competition_nested("score/lists/#{hidden_list.id}.pdf")
      expect(response).to redirect_to(competition_nested("score/lists/#{hidden_list.id}"))
    end

    it 'denies everything else' do
      get competition_nested("score/lists/#{list.id}/edit_times")
      expect_access_denied
      patch competition_nested("score/lists/#{list.id}"), params: { score_list: { name: 'Neu' } }
      expect_access_denied
      get competition_nested("score/lists/#{list.id}/move")
      expect_access_denied
      get competition_nested('editing/edit')
      expect_access_denied
      get competition_nested('teams/new')
      expect_access_denied
      get competition_nested('accesses')
      expect_access_denied
      expect(list.reload.name).to eq 'Lauf A'
    end
  end

  context 'with permission selected_results' do
    before { login(:selected_results, [hidden_list]) }

    it 'allows times only for selected lists, also hidden ones' do
      get competition_nested('score/lists')
      expect(response.body).to include("score/lists/#{hidden_list.id}")

      get competition_nested("score/lists/#{hidden_list.id}")
      expect(response.body).to include('Zeiten bearbeiten')
      get competition_nested("score/lists/#{hidden_list.id}.pdf")
      expect(response).to have_http_status(:success)

      edit_run(hidden_list)
      expect(response).to have_http_status(:success)
      update_run(hidden_list, '23.45')
      expect(hidden_list.entries.first.reload.time).to eq 2345

      edit_run(list)
      expect_access_denied
    end

    it 'grants no list after the selected list is deleted' do
      hidden_list.destroy!

      edit_run(list)
      expect_access_denied
      get competition_nested("score/lists/#{list.id}")
      expect(response.body).not_to include('Zeiten bearbeiten')
    end
  end
end
