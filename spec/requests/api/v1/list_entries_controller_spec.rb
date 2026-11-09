# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ListEntriesController do
  let(:competition) { create(:competition) }
  let(:access) { ApiAccess.create!(competition:, name: 'Uhr') }
  let(:separate) { false }
  let(:list) { create(:score_list, competition:, separate_target_times: separate) }
  let(:entry) do
    create(:score_list_entry, list:, competition:, assessment: list.assessments.first,
                              entity: create(:person, :with_team, competition:, band: list.assessments.first.band))
  end
  let(:headers) { api_headers(access) }

  def update_entry(target: entry, **attributes)
    patch("/api/v1/list_entries/#{target.id}", params: { version: target.api_version, **attributes }, headers:,
                                               as: :json)
  end

  it 'saves time and state' do
    update_entry(time: 2234, result_type: 'valid')
    expect_documented(200)
    expect(json).to include('time' => 2234, 'result_type' => 'valid')
    expect(json['version']).not_to eq entry.api_version
    expect(entry.reload).to have_attributes(time: 2234, result_type: :valid)
  end

  it 'ignores target times on lists without separate targets' do
    update_entry(time: 2234, time_left_target: 1, time_right_target: 2, result_type: 'valid')
    expect_documented(200)
    expect(entry.reload).to have_attributes(time: 2234, time_left_target: nil, time_right_target: nil)
  end

  context 'with separate targets' do
    let(:separate) { true }

    it 'ignores time and calculates it from the targets' do
      update_entry(time: 1, time_left_target: 2200, time_right_target: 2300, result_type: 'valid')
      expect_documented(200)
      expect(entry.reload).to have_attributes(time: 2300, time_left_target: 2200, time_right_target: 2300)
    end

    it 'rejects a valid state with only one target' do
      update_entry(time_left_target: 2200, result_type: 'valid')
      expect_documented(422)
      expect(json['fields']).to eq('time' => ['blank'])
      expect(entry.reload).to be_result_waiting
    end

    it 'keeps a partial result while waiting' do
      update_entry(time_left_target: 2200)
      expect_documented(200)
      expect(entry.reload).to have_attributes(time: nil, time_left_target: 2200)
    end
  end

  it 'rejects invalid values' do
    update_entry(time: 'abc')
    expect(response).to have_http_status(:unprocessable_content)
    expect(json['fields']).to eq('time' => ['not_a_number'])

    update_entry(time: 0)
    expect_documented(422)
    expect(json['fields']).to eq('time' => ['greater_than'])

    update_entry(result_type: 'foo')
    expect(json['fields']).to eq('result_type' => ['inclusion'])

    update_entry(result_type: 'valid')
    expect(json['fields']).to eq('time' => ['blank'])
  end

  it 'accepts invalid and no_run without a time' do
    update_entry(result_type: 'invalid')
    expect_documented(200)
    expect(entry.reload).to be_result_invalid
  end

  it 'answers with a conflict when the version is outdated or missing' do
    version = entry.api_version
    entry.update!(time: 2000, result_type: 'valid')

    patch("/api/v1/list_entries/#{entry.id}", params: { version:, time: 2234 }, headers:, as: :json)
    expect_documented(409)
    expect(json['entry']).to include('time' => 2000)

    patch("/api/v1/list_entries/#{entry.id}", params: { time: 2234 }, headers:, as: :json)
    expect(response).to have_http_status(:conflict)
    expect(entry.reload.time).to eq 2000
  end

  it 'overwrites a result when the version matches' do
    entry.update!(time: 2000, result_type: 'valid')
    update_entry(time: 2234)
    expect_documented(200)
    expect(entry.reload.time).to eq 2234
  end

  it 'does not change other attributes' do
    update_entry(track: 2, run: 5)
    expect(entry.reload).to have_attributes(track: 1, run: 1)
  end

  it 'does not reach entries of lists that are not selected' do
    other_list = create(:score_list, competition:)
    access.update!(permission: :selected_results, score_list_ids: [other_list.id])
    update_entry(time: 2234)
    expect_documented(404)
  end

  it 'does not reach entries of other competitions' do
    other = create(:competition)
    other_list = create(:score_list, competition: other)
    assessment = other_list.assessments.first
    person = create(:person, :with_team, competition: other, band: assessment.band)
    other_entry = create(:score_list_entry, list: other_list, competition: other, assessment:, entity: person)
    update_entry(target: other_entry, time: 2234)
    expect_documented(404)
  end
end
