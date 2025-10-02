# frozen_string_literal: true

module Genderable
  GENDERS = { female: 0, male: 1 }.freeze
  KEYS = %i[female male].freeze

  extend ActiveSupport::Concern

  included do
    enum :gender, GENDERS
    scope :gender, ->(gender) { where(gender: GENDERS[gender.to_sym]) }
    scope :order_by_gender, ->(gender) { order(gender: gender.to_s == 'female' ? :asc : :desc) }
  end
end
