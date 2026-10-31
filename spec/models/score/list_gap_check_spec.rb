# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::ListGapCheck do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let!(:assessment) { create(:assessment, competition:, band:) }
  let(:team) { create(:team, competition:, band:) }
  let(:people) { Array.new(8) { create(:person, :generated, competition:, band:, team:) } }

  let(:first_list) { create(:score_list, competition:, name: 'HL', track_count: 1) }
  let(:second_list) { create(:score_list, competition:, name: 'HB', track_count: 1) }

  def fill(list, entities)
    entities.each_with_index do |entity, index|
      create(:score_list_entry, competition:, list:, entity:, run: index + 1, track: 1)
    end
    list.reload
  end

  def conflict_names(list)
    described_class.new(list).conflicts.map { |c| [c.entry.entity, c.other_list, c.other_run, c.at_end] }
  end

  it 'reports less than three runs between the starts' do
    fill(first_list, people.first(6))

    # Letzter Lauf, dann Lauf 3: 0 + 2 Läufe dazwischen
    fill(second_list, [people[6], people[7], people[5]])
    expect(conflict_names(second_list)).to contain_exactly([people[5], first_list, 6, true])
    expect(conflict_names(first_list)).to contain_exactly([people[5], second_list, 3, false])
    expect(described_class.new(second_list)).not_to be_valid
  end

  it 'does not report three runs between the starts' do
    fill(first_list, people.first(6))

    # Vorletzter Lauf, dann Lauf 3: 1 + 2 Läufe dazwischen
    fill(second_list, [people[6], people[7], people[4]])
    expect(described_class.new(second_list)).to be_valid
    expect(described_class.new(first_list)).to be_valid
  end

  it 'uses starting times for the direction' do
    fill(first_list, people.first(6))
    fill(second_list, [people[6], people[7], people[5]])
    first_list.update!(starting_time: Time.zone.local(2024, 2, 29, 9))
    second_list.update!(starting_time: Time.zone.local(2024, 2, 29, 11))

    expect(conflict_names(second_list)).to contain_exactly([people[5], first_list, 6, true])
    expect(conflict_names(first_list)).to contain_exactly([people[5], second_list, 3, false])

    first_list.update!(starting_time: Time.zone.local(2024, 2, 29, 13))
    expect(described_class.new(second_list)).to be_valid
    expect(described_class.new(first_list)).to be_valid
  end

  it 'only compares lists of the same day or without date' do
    fill(first_list, people.first(4))
    fill(second_list, people.first(4).reverse)

    second_list.update!(date: Date.new(2024, 3, 1))
    expect(described_class.new(second_list)).not_to be_valid

    first_list.update!(date: Date.new(2024, 2, 29))
    expect(described_class.new(second_list)).to be_valid
    expect(described_class.new(first_list)).to be_valid
  end

  it 'compares relays as their team but not people with their team' do
    relay = TeamRelay.create!(team:, number: 1)
    fill(first_list, [relay])
    fill(second_list, [team, people[0]])

    expect(conflict_names(second_list)).to contain_exactly([team, first_list, 1, true])

    third_list = fill(create(:score_list, competition:, name: 'Ohne', track_count: 1), [people[1]])
    expect(described_class.new(third_list)).to be_valid
  end
end
