# frozen_string_literal: true

module Score::ResultRowSupport
  extend ActiveSupport::Concern

  included do
    include Certificates::StorageSupport

    attr_accessor :place
  end

  def starting_time_required?
    false
  end

  def competition_result_valid?
    true
  end
end
