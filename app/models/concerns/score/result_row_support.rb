# frozen_string_literal: true

module Score::ResultRowSupport
  extend ActiveSupport::Concern

  included do
    include Certificates::StorageSupport
  end

  def place
    result.add_places if @place.nil?
    @place
  end

  def place=(new_place)
    @place = new_place
  end

  def starting_time_required?
    false
  end
end
