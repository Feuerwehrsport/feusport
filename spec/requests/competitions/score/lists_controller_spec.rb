# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::List do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:male) { create(:band, :male, competition:) }
  let!(:assessment_male) { create(:assessment, competition:, discipline: la, band: male) }
  let!(:assessment_female) { create(:assessment, competition:, discipline: la, band: female) }
  let!(:assessment_hl_female) { create(:assessment, competition:, discipline: hl, band: female) }

  let!(:team_female) { create(:team, band: female, competition:) }
  let!(:team_male1) { create(:team, band: male, competition:) }
  let!(:team_male2) { create(:team, band: male, competition:) }

  let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl_female) }
  let(:result_la) { create(:score_result, competition:, assessment: assessment_female) }
  let(:person1) { create(:person, :generated, band: female, competition:) }
  let(:person2) { create(:person, :generated, band: female, competition:) }
  let(:person3) { create(:person, :generated, band: female, competition:) }

  describe 'create lists' do
    it 'uses list factory' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/lists"
      expect(response).to match_html_fixture.with_affix('index-empty')

      get "/#{competition.year}/#{competition.slug}/score/list_factories/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/score/list_factories",
           params: { score_list_factory: { next_step: 'assessments' } }
      expect(response).to match_html_fixture.with_affix('new-with-error').for_status(422)

      post "/#{competition.year}/#{competition.slug}/score/list_factories",
           params: { score_list_factory: { discipline_id: la.id,
                                           next_step: 'assessments' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-assessments')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { assessment_ids: [assessment_male.id, assessment_female.id],
                                            next_step: 'names' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-names')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { name: 'Löschangriff Nass - Lauf 1', shortcut: 'Lauf 1',
                                            next_step: 'tracks' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-tracks')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { track_count: '2',
                                            next_step: 'results' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-results-no-results')

      result_male = create(:score_result, competition:, assessment: assessment_male)
      result_female = create(:score_result, competition:, assessment: assessment_female)

      get "/#{competition.year}/#{competition.slug}/score/list_factories/edit"
      expect(response).to match_html_fixture.with_affix('new-results')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { result_ids: [result_male.id, result_female.id],
                                            next_step: 'generator' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { type: '',
                                            next_step: 'generator_params' } }
      expect(response).to match_html_fixture.with_affix('new-generator_params-error').for_status(422)

      # Score::ListFactories::TrackChange
      Score::ListFactory.last.update!(next_step: :generator, type: 'Score::ListFactory')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { type: 'Score::ListFactories::TrackChange',
                                            next_step: 'generator_params' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator_params_track_change')

      team_list = create_score_list(result_male, team_female => :waiting).tap do |l|
        l.update!(assessments: [assessment_male, assessment_female])
      end

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { before_list_id: team_list.id,
                                            next_step: 'finish' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator_params_track_change_finish')

      # Score::ListFactories::Best

      Score::ListFactory.last.update!(next_step: :generator, type: 'Score::ListFactory', before_list_id: nil)

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { type: 'Score::ListFactories::Best',
                                            next_step: 'generator_params' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator_params_best')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { before_result_id: result_male.id, best_count: 30,
                                            next_step: 'finish' } }
      expect(response).to match_html_fixture.with_affix('new-generator_params_best_error').for_status(422)

      # Score::ListFactories::TrackSame

      Score::ListFactory.last.update!(next_step: :generator, type: 'Score::ListFactory', before_list_id: nil)

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { type: 'Score::ListFactories::TrackSame',
                                            next_step: 'generator_params' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator_params_track_same')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { before_list_id: team_list.id,
                                            next_step: 'finish' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator_params_track_same_finish')

      # Score::ListFactories::Simple
      Score::ListFactory.last.update!(next_step: :generator, type: 'Score::ListFactory')

      patch "/#{competition.year}/#{competition.slug}/score/list_factories",
            params: { score_list_factory: { type: 'Score::ListFactories::Simple',
                                            next_step: 'generator_params' } }
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('new-generator_params_single_finish')

      expect do
        patch "/#{competition.year}/#{competition.slug}/score/list_factories",
              params: { score_list_factory: { hidden: '1', separate_target_times: '1', show_best_of_run: '1',
                                              next_step: 'create' } }
        follow_redirect!
      end.to change(Score::ListEntry, :count).by(3)
    end
  end

  describe 'edit list' do
    let!(:person_list) { create_score_list(result_hl, person1 => :waiting, person2 => :waiting, person3 => :waiting) }
    let!(:team_list) { create_score_list(result_la, team_female => :waiting) }

    it 'shows form and updates' do
      sign_in user

      person_list.update!(hidden: true)

      get "/#{competition.year}/#{competition.slug}/score/lists"
      expect(response).to match_html_fixture.with_affix('index-with-two')

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}"
      expect(response).to match_html_fixture.with_affix('show-person')

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit-person')

      patch "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}",
            params: { score_list: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)

      patch "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}",
            params: { score_list: { name: 'new name' } }
      follow_redirect!

      expect(person_list.reload.name).to eq 'new name'

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/edit_times"
      expect(response).to match_html_fixture.with_affix('edit-times-person')

      entries = person_list.reload.entries
      patch "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}",
            params: { score_list: { entries_attributes: {
              '0' => {
                'id' => entries[0].id,
                'track' => '1', 'edit_second_time' => '12.23', 'edit_second_time_before' => '12',
                'result_type_before' => 'waiting', 'result_type' => 'valid'
              },
              '1' => {
                'id' => entries[1].id,
                'track' => '2', 'edit_second_time' => '13.44', 'edit_second_time_before' => '',
                'result_type_before' => 'waiting', 'result_type' => 'valid'
              },
              '2' => {
                'id' => entries[2].id,
                'track' => '1', 'edit_second_time' => '13.44', 'edit_second_time_before' => '',
                'result_type_before' => 'waiting', 'result_type' => 'valid'
              },
            } } }
      expect(response).to match_html_fixture.with_affix('edit-times-db-changed').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}",
            params: { score_list: { entries_attributes: {
              '0' => {
                'id' => entries[0].id,
                'track' => '1', 'edit_second_time' => '12.23', 'edit_second_time_before' => '',
                'result_type_before' => 'waiting', 'result_type' => 'valid'
              },
              '1' => {
                'id' => entries[1].id,
                'track' => '2', 'edit_second_time' => '13.44', 'edit_second_time_before' => '',
                'result_type_before' => 'waiting', 'result_type' => 'valid'
              },
              '2' => {
                'id' => entries[2].id,
                'track' => '1', 'edit_second_time' => '13.44', 'edit_second_time_before' => '',
                'result_type_before' => 'waiting', 'result_type' => 'valid'
              },
            } } }
      follow_redirect!

      get "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}"
      expect(response).to match_html_fixture.with_affix('show-team')

      get "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}?destroy_index=1"
      expect(response).to match_html_fixture.with_affix('show-team-with-destroy')

      get "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}/" \
          "destroy_entity/#{team_list.entries.first.id}"
      expect(response).to match_html_fixture.with_affix('show-team-destroy-dialog')

      expect do
        patch "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}",
              params: { score_list: { entries_attributes: {
                '0' => { '_destroy' => '1', 'id' => team_list.entries.first.id },
              } } }
      end.to change(Score::ListEntry, :count).by(-1)

      expect do
        delete "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}"
      end.to change(described_class, :count).by(-1)
    end
  end

  describe 'move list' do
    let!(:person_list) { create_score_list(result_hl, person1 => :waiting, person2 => :waiting, person3 => :waiting) }

    it 'moves entries' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/move"
      expect(response).to match_html_fixture.with_affix('move')

      entries = person_list.reload.entries
      new_order = {
        '0' => nil,
        '1' => entries[1].id,
        '2' => entries[0].id,
        '3' => entries[2].id,
        '4' => nil,
        '5' => nil,
      }

      post "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/move",
           params: {
             save: false,
             new_order:,
             list: { new_order:, save: false },
           }
      expect(response).to match_html_fixture.with_affix('move-new-order')

      post "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/move",
           params: {
             save: true,
             new_order:,
             list: { new_order:, save: true },
           }
      expect(entries[0].reload.run).to eq 2
    end
  end

  describe 'add to list' do
    let!(:person_list) { create_score_list(result_hl, person1 => :waiting) }

    it 'shows and add entries' do
      sign_in user

      person2
      person3

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/select_entity"
      expect(response).to match_html_fixture.with_affix('select')

      expect do
        patch "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}",
              params: { score_list: { entries_attributes: {
                '0' => {
                  entity_id: person2.id,
                  run: '1',
                  track: '2',
                  entity_type: 'Person',
                  assessment_id: assessment_hl_female.id,
                  assessment_type: 'group_competitor',
                },
              } } }
      end.to change(Score::ListEntry, :count).by(1)

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}/select_entity?all_entities=1"
      expect(response).to match_html_fixture.with_affix('select-with-all')

      expect do
        patch "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}",
              params: { score_list: { entries_attributes: {
                '0' => {
                  entity_id: person2.id,
                  run: '2',
                  track: '3',
                  entity_type: 'Person',
                  assessment_id: nil,
                  assessment_type: 'group_competitor',
                },
              } } }
      end.not_to change(Score::ListEntry, :count)
      expect(response).to match_html_fixture.with_affix('select-with-error').for_status(422)
    end

    context 'when discipline is like_fire_relay' do
      let!(:fs) { create(:discipline, :fs, competition:) }
      let!(:assessment_fs) { create(:assessment, competition:, discipline: fs, band: male) }
      let(:result_fs) { create(:score_result, competition:, assessment: assessment_fs) }
      let(:relay1) { TeamRelay.create!(team: team_male1) }
      let!(:fs_list) { create_score_list(result_fs, relay1 => :waiting) }

      it 'shows and add entries' do
        sign_in user

        get "/#{competition.year}/#{competition.slug}/score/lists/#{fs_list.id}/select_entity"
        expect(response).to match_html_fixture.with_affix('select')
      end
    end
  end

  describe 'edit list entity' do
    let!(:person_list) { create_score_list(result_hl, person1 => 1234, person2 => :waiting, person3 => :waiting) }

    it 'updates entity' do
      sign_in user

      get competition_nested("score/lists/#{person_list.id}?edit_index=1")
      expect(response).to match_html_fixture.with_affix('show-team-with-edit')

      get competition_nested("score/lists/#{person_list.id}/edit_entity/#{person_list.entries.first.id}")
      expect(response).to match_html_fixture.with_affix('show-edit-dialog')

      patch competition_nested("score/lists/#{person_list.id}"),
            params: { score_list: { entries_attributes: {
              '0' => { 'id' => person_list.entries.first.id, 'entity_id' => person2.id },
            } } }

      expect(person_list.entries.pluck(:entity_id)).to eq [person2.id, person2.id, person3.id]
    end
  end

  describe 'copy list' do
    let!(:person_list) { create_score_list(result_hl, person1 => 1234, person2 => :waiting, person3 => :waiting) }

    it 'duplicates list with factory' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}"

      expect do
        get "/#{competition.year}/#{competition.slug}/score/list_factories/copy_list/#{person_list.id}"
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/list_factories/edit"
      end.to change(Score::ListFactory, :count).by(1)

      get "/#{competition.year}/#{competition.slug}/score/list_factories/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      factory = Score::ListFactory.last
      expect(factory).to be_instance_of(Score::ListFactories::TrackChange)
      expect(factory.discipline).to eq hl
      expect(factory.results).to eq [result_hl]
    end
  end

  describe 'abort list factory' do
    it 'destroys list factory' do
      sign_in user

      # get not existing factory
      get "/#{competition.year}/#{competition.slug}/score/list_factories/edit"
      follow_redirect!

      post "/#{competition.year}/#{competition.slug}/score/list_factories",
           params: { score_list_factory: { discipline_id: la.id,
                                           next_step: 'assessments' } }
      follow_redirect!

      expect do
        delete "/#{competition.year}/#{competition.slug}/score/list_factories"
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/score/lists"
      end.to change(Score::ListFactory, :count).by(-1)
    end
  end

  describe 'export list' do
    let!(:person_list) { create_score_list(result_hl, person1 => 1234, person2 => :waiting, person3 => :waiting) }
    let!(:team_list) { create_score_list(result_la, team_female => :waiting) }

    it 'shows as pdf and xlsx' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}.pdf"
      expect(response).to match_pdf_fixture.with_affix('person-normal-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="hakenleitersteigen-frauen-lauf-1.pdf"; ' \
        "filename*=UTF-8''hakenleitersteigen-frauen-lauf-1.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}.pdf?more_columns=true"
      expect(response).to match_pdf_fixture.with_affix('person-more-columns-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="hakenleitersteigen-frauen-lauf-1-kampfrichter.pdf"; ' \
        "filename*=UTF-8''hakenleitersteigen-frauen-lauf-1-kampfrichter.pdf",
      )
      expect(response).to have_http_status(:success)

      # GET index XLSX
      get "/#{competition.year}/#{competition.slug}/score/lists/#{person_list.id}.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="hakenleitersteigen-frauen-lauf-1.xlsx"; ' \
        "filename*=UTF-8''hakenleitersteigen-frauen-lauf-1.xlsx",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}.pdf"
      expect(response).to match_pdf_fixture.with_affix('team-normal-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="loschangriff-nass-frauen-lauf-1.pdf"; ' \
        "filename*=UTF-8''loschangriff-nass-frauen-lauf-1.pdf",
      )
      expect(response).to have_http_status(:success)

      get "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}.pdf?more_columns=true"
      expect(response).to match_pdf_fixture.with_affix('team-more-columns-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="loschangriff-nass-frauen-lauf-1-kampfrichter.pdf"; ' \
        "filename*=UTF-8''loschangriff-nass-frauen-lauf-1-kampfrichter.pdf",
      )
      expect(response).to have_http_status(:success)

      # GET index XLSX
      get "/#{competition.year}/#{competition.slug}/score/lists/#{team_list.id}.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        'attachment; filename="loschangriff-nass-frauen-lauf-1.xlsx"; ' \
        "filename*=UTF-8''loschangriff-nass-frauen-lauf-1.xlsx",
      )
      expect(response).to have_http_status(:success)
    end
  end
end
