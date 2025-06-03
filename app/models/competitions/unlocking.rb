# frozen_string_literal: true

class Competitions::Unlocking
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :competition

  attribute :confirm, :boolean, default: false
  validates :confirm, acceptance: true

  def save
    return false unless valid?

    competition.update(locked_at: nil)
  end
end
