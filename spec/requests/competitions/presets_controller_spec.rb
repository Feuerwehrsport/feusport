# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/presets' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }

  describe 'use presets' do
    it 'use nothing' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/presets"
      expect(response).to match_html_fixture.with_affix('index')

      get "/#{competition.year}/#{competition.slug}/presets/nothing/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/presets/nothing"
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"

      expect(competition.reload.preset_ran?).to be(true)

      get "/#{competition.year}/#{competition.slug}/presets"
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      expect(flash['alert']).to eq 'Es wurde bereits eine Vorlage gewählt.'
    end

    it 'use fire_attack' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/presets/fire_attack/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/presets/fire_attack",
            params: { preset: { selected_bands: ['', 'female', 'male'], selected_assessments: '' } }
      expect(response).to match_html_fixture.with_affix('edit-with-error').for_status(422)

      expect do
        expect do
          expect do
            expect do
              patch "/#{competition.year}/#{competition.slug}/presets/fire_attack",
                    params: { preset: { selected_bands: ['', 'female', 'male'], selected_assessments: 'single' } }
              expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
            end.to change(Band, :count).by(2)
          end.to change(Discipline, :count).by(1)
        end.to change(Assessment, :count).by(2)
      end.to change(Score::Result, :count).by(2)
    end

    it 'use fire_attack with multiple groups' do
      sign_in user

      expect do
        expect do
          expect do
            expect do
              patch "/#{competition.year}/#{competition.slug}/presets/fire_attack",
                    params: { preset: { selected_bands: ['', 'youth', 'male'], selected_assessments: 'din_tgl' } }
              expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
            end.to change(Band, :count).by(2)
          end.to change(Discipline, :count).by(1)
        end.to change(Assessment, :count).by(3)
      end.to change(Score::Result, :count).by(3)
    end

    it 'use single_disciplines' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/presets/single_disciplines/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/presets/single_disciplines",
            params: { preset: { selected_bands: ['', 'female', 'male'], selected_disciplines: '' } }
      expect(response).to match_html_fixture.with_affix('edit-with-error').for_status(422)

      expect do
        expect do
          expect do
            expect do
              patch "/#{competition.year}/#{competition.slug}/presets/single_disciplines",
                    params: { preset: { selected_bands: ['', 'female', 'male'], selected_disciplines: %w[hl hb] } }
              expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
            end.to change(Band, :count).by(2)
          end.to change(Discipline, :count).by(2)
        end.to change(Assessment, :count).by(4)
      end.to change(Score::Result, :count).by(4)
    end

    it 'use single_disciplines with zk' do
      sign_in user

      expect do
        expect do
          expect do
            expect do
              patch "/#{competition.year}/#{competition.slug}/presets/single_disciplines",
                    params: { preset: { selected_bands: ['', 'female', 'male'], selected_disciplines: %w[hl hb zk] } }
              expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
            end.to change(Band, :count).by(2)
          end.to change(Discipline, :count).by(2)
        end.to change(Assessment, :count).by(4)
      end.to change(Score::Result, :count).by(6)
    end
  end
end
