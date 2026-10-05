# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_people
#
#  id                           :bigint           not null, primary key
#  dummy                        :boolean          default(FALSE), not null
#  first_name                   :string(100)      not null
#  gender                       :integer          not null
#  last_name                    :string(100)      not null
#  personal_best_hb             :integer
#  personal_best_hb_competition :string
#  personal_best_hl             :integer
#  personal_best_hl_competition :string
#  personal_best_zk             :integer
#  personal_best_zk_competition :string
#  saison_best_hb               :integer
#  saison_best_hb_competition   :string
#  saison_best_hl               :integer
#  saison_best_hl_competition   :string
#  saison_best_zk               :integer
#  saison_best_zk_competition   :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
require 'rails_helper'

RSpec.describe FireSportStatistics::Person do
  let(:person) { build(:fire_sport_statistics_person, :with_statistics) }

  describe '#name' do
    it 'returns full name' do
      expect(person.name).to eq 'Alfred Meier'
    end
  end

  describe '#personal_best_table' do
    it 'returns table with all disciplines' do
      expect(person.personal_best_table).to eq(
        hb: { ['PB', 'Persönliche Bestleistung'] => ['20,22', 'Wettkampf 1'],
              %w[SB Saison-Bestleistung] => ['20,23', 'Wettkampf 4'] },
        hl: { ['PB', 'Persönliche Bestleistung'] => ['19,22', 'Wettkampf 2'],
              %w[SB Saison-Bestleistung] => ['19,23', 'Wettkampf 5'] },
        zk: { ['PB', 'Persönliche Bestleistung'] => ['40,22', 'Wettkampf 3'],
              %w[SB Saison-Bestleistung] => ['40,23', 'Wettkampf 6'] },
      )
    end

    it 'skips blank values' do
      person = build(:fire_sport_statistics_person, personal_best_hl: 1922, personal_best_hl_competition: 'W')
      expect(person.personal_best_table).to eq(hl: { ['PB', 'Persönliche Bestleistung'] => ['19,22', 'W'] })
    end
  end

  describe '#new_personal_best?' do
    let(:discipline) { Struct.new(:key).new('hl') }
    let(:list) { Struct.new(:discipline).new(discipline) }

    def result(compare_time, list: nil)
      if list
        Struct.new(:list, :compare_time).new(list, compare_time)
      else
        Struct.new(:compare_time).new(compare_time)
      end
    end

    it 'returns false for blank result' do
      expect(person.new_personal_best?(nil)).to be false
    end

    it 'compares with discipline of list' do
      expect(person.new_personal_best?(result(1900, list:))).to be true
      expect(person.new_personal_best?(result(1922, list:))).to be false
      expect(person.new_personal_best?(result(2000, list:))).to be false
    end

    it 'uses zk without list' do
      expect(person.new_personal_best?(result(4000))).to be true
      expect(person.new_personal_best?(result(4100))).to be false
    end

    it 'returns false for other disciplines' do
      discipline.key = 'la'
      expect(person.new_personal_best?(result(1000, list:))).to be false
    end

    it 'returns true for any valid time without personal best' do
      person = build(:fire_sport_statistics_person)
      expect(person.new_personal_best?(result(9999))).to be true
    end
  end
end
