# frozen_string_literal: true

# == Schema Information
#
# Table name: series_round_competition_associations
#
#  id             :uuid             not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  round_id       :bigint           not null
#
# Indexes
#
#  index_series_round_competition_associations_on_competition_id  (competition_id)
#  index_series_round_competition_associations_on_round_id        (round_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Series::RoundCompetitionAssociation < ApplicationRecord
  belongs_to :round, class_name: 'Series::Round'
  belongs_to :competition, class_name: 'Competition'

  schema_validations
end
