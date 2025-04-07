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
class FireSportStatistics::Person < ApplicationRecord
  include Genderable
  BEST_TABLE_HEAD = { personal_best: ['PB', 'Persönliche Bestleistung'],
                      saison_best: %w[SB Saison-Bestleistung] }.freeze

  has_many :team_associations, class_name: 'FireSportStatistics::TeamAssociation', dependent: :destroy,
                               inverse_of: :person
  has_many :teams, through: :team_associations, class_name: 'FireSportStatistics::Team'
  has_many :series_participations, class_name: 'Series::PersonParticipation', dependent: :destroy, inverse_of: :person
  has_one :person, class_name: '::Person', inverse_of: :fire_sport_statistics_person,
                   foreign_key: :fire_sport_statistics_person_id, dependent: :nullify
  has_many :spellings, class_name: 'FireSportStatistics::PersonSpelling', dependent: :destroy, inverse_of: :person

  schema_validations

  auto_strip_attributes :first_name, :last_name

  scope :where_name_like, ->(name) do
    query = "%#{name.chars.join('%')}%"
    spelling_query = FireSportStatistics::PersonSpelling.where("(first_name || ' ' || last_name) ILIKE ?", query)
                                                        .select(:person_id)
    where("(first_name || ' ' || last_name) ILIKE ? OR id IN (#{spelling_query.to_sql})", query)
  end
  scope :order_by_teams, ->(teams) do
    order_condition = teams.joins(:team_associations)
                           .where(arel_table[:id].eq(FireSportStatistics::TeamAssociation.arel_table[:person_id]))
                           .arel.exists
                           .desc
    order(order_condition)
  end
  scope :for_person, ->(person) do
    where(dummy: false).where_name_like("#{person.first_name}#{person.last_name}")
  end
  scope :dummies, -> { where(dummy: true) }

  def self.dummy(person)
    find_or_create_by(last_name: person.last_name, first_name: person.first_name, gender: person.band.gender,
                      dummy: true)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def team_list
    teams.map(&:short).join(', ')
  end

  def personal_best_table
    @personal_best_table ||= begin
      table = {}
      %i[hb hl zk].each do |discipline|
        BEST_TABLE_HEAD.each do |method, short|
          next if public_send(:"#{method}_#{discipline}").blank?

          table[discipline] ||= {}
          table[discipline][short] = [
            Firesport::Time.second_time(public_send(:"#{method}_#{discipline}")),
            public_send(:"#{method}_#{discipline}_competition"),
          ]
        end
      end
      table
    end
  end

  def new_personal_best?(current_result)
    return false if current_result.blank?

    discipline = current_result.try(:list)&.discipline&.key || :zk
    best_time = public_send(:"personal_best_#{discipline}") || Firesport::INVALID_TIME
    best_time > current_result.compare_time
  end
end
