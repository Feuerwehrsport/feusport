# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/certificates/lists' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:template) { create(:certificates_template, competition:) }
  let!(:text_field1) { create(:certificates_text_field, :team_name, template:) }
  let!(:text_field2) { create(:certificates_text_field, :free_text, template:) }

  let!(:hl) { create(:discipline, :hl, competition:) }
  let!(:female) { create(:band, :female, competition:) }
  let!(:assessment_hl_female) { create(:assessment, competition:, discipline: hl, band: female) }

  let!(:team_female) { create(:team, band: female, competition:) }

  let!(:result_hl) { create(:score_result, competition:, assessment: assessment_hl_female) }
  let!(:person1) { create(:person, :generated, competition:) }
  let!(:person2) { create(:person, :generated, competition:) }
  let!(:person_list) { create_score_list(result_hl, person1 => 123, person2 => 456) }

  describe 'create certificates' do
    it 'uses template and results' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/certificates/lists/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/certificates/lists",
           params: { certificates_list: { template_id: template.id } }
      expect(response).to match_html_fixture.with_affix('new-with-error').for_status(422)

      post "/#{competition.year}/#{competition.slug}/certificates/lists",
           params: { certificates_list: { template_id: template.id, background_image: '0',
                                          score_result_id: result_hl.id } }
      expect(response).to redirect_to(
        "/#{competition.year}/#{competition.slug}/certificates/lists/export.pdf" \
        '?certificates_list%5Bbackground_image%5D=false&certificates_list%5Bcompetition_result_id%5D=&' \
        'certificates_list%5Bgroup_score_result_id%5D=&certificates_list%5B' \
        "score_result_id%5D=#{result_hl.id}&certificates_list%5Bseries_person_assessment_id%5D=&" \
        "certificates_list%5Bseries_team_assessment_id%5D=&certificates_list%5Btemplate_id%5D=#{template.id}",
      )
      follow_redirect!
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="urkunden-hakenleitersteigen-frauen.pdf"; ' \
        "filename*=UTF-8''urkunden-hakenleitersteigen-frauen.pdf",
      )
      expect(response).to have_http_status(:success)
      expect(response.body.size).to be_between 24_000, 25_000

      # invalid list redirects
      get "/#{competition.year}/#{competition.slug}/certificates/lists/export?" \
          'certificates_list%5Bbackground_image%5D=false'
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}/certificates/lists/new"
    end
  end
end
