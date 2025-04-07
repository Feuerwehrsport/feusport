# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factory_bands
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  band_id         :uuid             not null
#  list_factory_id :uuid             not null
#
# Indexes
#
#  index_score_list_factory_bands_on_band_id          (band_id)
#  index_score_list_factory_bands_on_list_factory_id  (list_factory_id)
#
# Foreign Keys
#
#  fk_rails_...  (band_id => bands.id)
#  fk_rails_...  (list_factory_id => score_list_factories.id)
#
class Score::ListFactoryBand < ApplicationRecord
  belongs_to :band
  belongs_to :list_factory, class_name: 'Score::ListFactory'

  schema_validations
end
