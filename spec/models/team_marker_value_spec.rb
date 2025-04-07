# frozen_string_literal: true

# == Schema Information
#
# Table name: team_marker_values
#
#  id             :uuid             not null, primary key
#  boolean_value  :boolean          default(FALSE), not null
#  date_value     :date
#  string_value   :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  team_id        :uuid             not null
#  team_marker_id :uuid             not null
#
# Indexes
#
#  index_team_marker_values_on_team_id                     (team_id)
#  index_team_marker_values_on_team_marker_id              (team_marker_id)
#  index_team_marker_values_on_team_marker_id_and_team_id  (team_marker_id,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (team_marker_id => team_markers.id)
#
require 'rails_helper'

RSpec.describe TeamMarkerValue do
  let(:team_marker) { build(:team_marker) }

  it 'shows values' do
    value = described_class.new(team_marker:)

    expect(value.value).to eq 'Nein'
    expect(value.value_present?).to be false
    value.boolean_value = false
    expect(value.value).to eq 'Nein'
    expect(value.value_present?).to be false
    value.boolean_value = true
    expect(value.value).to eq 'Ja'
    expect(value.value_present?).to be true

    team_marker.value_type = :date
    expect(value.value).to be_nil
    expect(value.value_present?).to be false
    value.date_value = Date.current
    expect(value.value).to eq I18n.l(Date.current)
    expect(value.value_present?).to be true

    team_marker.value_type = :string
    expect(value.value).to be_nil
    expect(value.value_present?).to be false
    value.string_value = 'text'
    expect(value.value).to eq 'text'
    expect(value.value_present?).to be true
  end
end
