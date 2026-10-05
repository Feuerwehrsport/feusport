# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonbAsText do
  let(:config) do
    [{ 'key' => 'male-hl', 'name' => 'HL-Männer', 'disciplines' => ['hl'],
       'calc_participations_count' => 1, 'ranking_logic' => ['points'] }]
  end

  it 'returns pretty generated json as text' do
    round = Series::Round.new(person_assessments_config_jsonb: config)
    expect(round.person_assessments_config_jsonb_text).to eq JSON.pretty_generate(config)
  end

  it 'returns assigned text' do
    round = Series::Round.new(person_assessments_config_jsonb_text: '[1')
    expect(round.person_assessments_config_jsonb_text).to eq '[1'
  end

  it 'parses assigned text before validation' do
    round = Series::Round.new(name: 'D-Cup', year: 2024, team_assessments_config_jsonb: [],
                              person_assessments_config_jsonb_text: config.to_json)
    expect(round).to be_valid
    expect(round.person_assessments_config_jsonb).to eq config
  end

  it 'ignores blank text' do
    round = Series::Round.new(name: 'D-Cup', year: 2024, team_assessments_config_jsonb: [],
                              person_assessments_config_jsonb: config, person_assessments_config_jsonb_text: '')
    expect(round).to be_valid
    expect(round.person_assessments_config_jsonb).to eq config
  end

  it 'adds error for invalid json' do
    round = Series::Round.new(name: 'D-Cup', year: 2024, team_assessments_config_jsonb: [],
                              person_assessments_config_jsonb: [], person_assessments_config_jsonb_text: '[1')
    expect(round).not_to be_valid
    expect(round.errors[:person_assessments_config_jsonb_text]).to include 'ist kein gültiges JSON'
  end
end
