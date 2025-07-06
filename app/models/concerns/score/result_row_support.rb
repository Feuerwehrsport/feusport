# frozen_string_literal: true

module Score::ResultRowSupport
  extend ActiveSupport::Concern

  included do
    include Certificates::StorageSupport
  end

  def place
    @place ||= result.place_for_row(self)
  end
end
