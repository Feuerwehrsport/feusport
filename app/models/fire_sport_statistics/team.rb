# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_teams
#
#  id          :bigint           not null, primary key
#  best_scores :jsonb
#  dummy       :boolean          default(FALSE), not null
#  name        :string(100)      not null
#  short       :string(50)       not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class FireSportStatistics::Team < ApplicationRecord
  BEST_TABLE_HEAD = { 'pb' => ['PB', 'Persönliche Bestleistung'].freeze,
                      'sb' => %w[SB Saison-Bestleistung].freeze }.freeze

  include FireSportStatistics::TeamScopes
  has_many :team_associations, class_name: 'FireSportStatistics::TeamAssociation', dependent: :destroy,
                               inverse_of: :team
  has_one :team, class_name: '::Team', inverse_of: :fire_sport_statistics_team, dependent: :nullify,
                 foreign_key: :fire_sport_statistics_team_id
  has_many :series_participations, class_name: 'Series::TeamParticipation', dependent: :destroy, inverse_of: :team
  belongs_to :federal_state

  auto_strip_attributes :name, :short
  schema_validations

  scope :where_name_like, ->(name) do
    name = name.strip.gsub(/^FF\s/i, '').gsub(/^Team\s/i, '').strip

    in_names = FireSportStatistics::Team.select(:id).like_name_or_short(name).to_sql
    in_spellings = FireSportStatistics::TeamSpelling.select(FireSportStatistics::TeamSpelling.arel_table[:team_id])
                                                    .like_name_or_short(name).to_sql
    where("#{table_name}.id IN (#{in_names}) OR #{table_name}.id IN (#{in_spellings})")
  end
  scope :for_team, ->(team) do
    where(dummy: false).where_name_like(team.name.to_s)
  end
  scope :dummies, -> { where(dummy: true) }

  def self.dummy(team)
    find_or_create_by(name: team.name, short: team.shortcut, dummy: true)
  end

  def team_best_table(gender)
    table = {}
    return if best_scores[gender].nil?

    %w[din tgl].each do |type|
      next if best_scores[gender][type].nil?

      BEST_TABLE_HEAD.each do |method, infos|
        next if best_scores[gender][type][method].nil?

        table[type] ||= {}
        table[type][infos] = [
          Firesport::Time.second_time(best_scores[gender][type][method][0]),
          best_scores[gender][type][method][1],
        ]
      end
    end
    table
  end
end
