# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::Monitor do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let(:assessment) { create(:assessment, competition:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }

  # results: Läufe mit Ergebnis (alle Bahnen gültig)
  def add_list(name, runs:, results: [], track_count: 2, **attributes)
    list = create(:score_list, competition:, name:, track_count:, assessments: [assessment], results: [result],
                               **attributes)
    (1..runs).each do |run|
      (1..track_count).each do |track|
        person = create(:person, competition:, band:, first_name: name, last_name: "#{run}-#{track}")
        create(:score_list_entry, list:, competition:, assessment:, entity: person, run:, track:,
                                  **(run.in?(results) ? { result_type: 'valid', time: 2000 } : {}))
      end
    end
    list
  end

  def states(block)
    block.runs.map { |run| [run.number, run.state] }
  end

  it 'shows nothing without lists' do
    add_list('Leer', runs: 0)
    monitor = described_class.new(competition)

    expect(monitor).to be_automatic
    expect(monitor.lists).to eq []
    expect(monitor.blocks).to eq []
  end

  it 'starts a list without results at the top' do
    list = add_list('A', runs: 3)
    block = described_class.new(competition).blocks.sole

    expect(block.list).to eq list
    expect(states(block)).to eq [[1, :current], [2, :upcoming], [3, :upcoming]]
    expect(block.runs.first.entries.map { |entry| entry.entity.last_name }).to eq %w[1-1 1-2]
  end

  it 'focuses the run after the last run with results and shows the last two results' do
    add_list('A', runs: 6, results: [1, 2, 4])
    block = described_class.new(competition).blocks.sole

    expect(states(block)).to eq [[2, :done], [4, :done], [5, :current], [6, :upcoming]]
  end

  it 'leaves out empty tracks and runs' do
    list = add_list('A', runs: 2, track_count: 1)
    list.update!(track_count: 2)
    list.entries.find_by(run: 2).update!(run: 4)
    block = described_class.new(competition).blocks.sole

    expect(states(block)).to eq [[1, :current], [4, :upcoming]]
    expect(block.runs.first.entries.map { |entry| entry&.entity&.last_name }).to eq ['1-1', nil]
  end

  it 'prefers running lists over pending and finished lists' do
    add_list('Fertig', runs: 1, results: [1])
    running1 = add_list('Laufend 1', runs: 3, results: [1])
    running2 = add_list('Laufend 2', runs: 3, results: [1])
    add_list('Offen', runs: 2)

    expect(described_class.new(competition).lists).to eq [running1, running2]
  end

  it 'takes the first pending list when no list is running' do
    add_list('Fertig', runs: 1, results: [1])
    pending = add_list('Offen 1', runs: 2)
    add_list('Offen 2', runs: 2)

    expect(described_class.new(competition).lists).to eq [pending]
  end

  it 'takes the last changed finished list at the end' do
    finished1 = add_list('Fertig 1', runs: 1, results: [1])
    add_list('Fertig 2', runs: 1, results: [1])
    finished1.touch

    block = described_class.new(competition).blocks.sole
    expect(block.list).to eq finished1
    expect(states(block)).to eq [[1, :done]]
  end

  it 'ignores hidden lists' do
    add_list('Versteckt', runs: 2, results: [1], hidden: true)
    pending = add_list('Offen', runs: 2)

    monitor = described_class.new(competition)
    expect(monitor.available_lists).to eq [pending]
    expect(monitor.lists).to eq [pending]
  end

  it 'uses the selected lists' do
    list1 = add_list('A', runs: 2)
    list2 = add_list('B', runs: 2, results: [1])
    hidden = add_list('C', runs: 2, hidden: true)

    monitor = described_class.new(competition, list_ids: [list2.id, hidden.id, 'unknown', ''])
    expect(monitor).not_to be_automatic
    expect(monitor.lists).to eq [list2]

    expect(described_class.new(competition, list_ids: [list2.id, list1.id]).lists).to eq [list1, list2]
  end

  describe 'following list' do
    it 'shows exactly one pending list below the end of the list' do
      add_list('A', runs: 4, results: [1, 2])
      following = add_list('B', runs: 20)

      block = described_class.new(competition).blocks.sole
      expect(block.following_list).to eq following
      expect(block.following_runs.map(&:number)).to eq (1..10).to_a
      expect(block.following_runs.map(&:state).uniq).to eq [:upcoming]
    end

    it 'shows nothing while the end is not reached' do
      add_list('A', runs: 20, results: [1])
      add_list('B', runs: 2)

      block = described_class.new(competition).blocks.sole
      expect(block.following_list).to be_nil
      expect(block.following_runs).to eq []
      expect(block.runs.size).to eq 2 + described_class::VISIBLE_RUNS - 1
    end

    it 'shows nothing if the next list is not clear' do
      add_list('A', runs: 3, results: [1])
      add_list('B', runs: 2)
      add_list('C', runs: 2)

      expect(described_class.new(competition).blocks.sole.following_list).to be_nil
    end

    it 'shows the following list only once' do
      add_list('A', runs: 3, results: [1])
      add_list('B', runs: 3, results: [1])
      following = add_list('C', runs: 2)

      blocks = described_class.new(competition).blocks
      expect(blocks.map(&:following_list)).to eq [following, nil]
    end

    it 'does not show a list which is already shown' do
      list1 = add_list('A', runs: 3)
      list2 = add_list('B', runs: 3)

      expect(described_class.new(competition).blocks.sole.following_list).to eq list2

      blocks = described_class.new(competition, list_ids: [list1.id, list2.id]).blocks
      expect(blocks.map(&:following_list)).to eq [nil, nil]
    end
  end
end
