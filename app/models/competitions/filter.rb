# frozen_string_literal: true

class Competitions::Filter
  include ActiveModel::Model
  include ActiveModel::Attributes

  SORTS = %w[date published].freeze

  attribute :sort, :string, default: 'date'
  attribute :distance, :integer
  attr_accessor :lnglat
  attr_reader :feature_ids

  def self.for_user(user)
    new(feature_ids: user.feature_ids, distance: user.distance, lnglat: user.lnglat)
  end

  def initialize(...)
    @feature_ids = []
    super
  end

  def sort=(value)
    super(value.in?(SORTS) ? value : 'date')
  end

  def feature_ids=(value)
    @feature_ids = Array(value).compact_blank.map(&:to_s)
  end

  def distance_active?
    lnglat.present? && distance.to_i.positive?
  end

  def active?
    feature_ids.present? || distance_active?
  end

  def customized?
    active? || sort_published?
  end

  def customizations_count
    feature_ids.count + (distance_active? ? 1 : 0) + (sort_published? ? 1 : 0)
  end

  def sort_published?
    sort == 'published'
  end

  def apply(competitions)
    if feature_ids.present?
      competitions = competitions.where(id: CompetitionFeature.where(feature_id: feature_ids).select(:competition_id))
    end
    competitions = competitions.near(lnglat, distance) if distance_active?
    competitions
  end

  def to_params
    {
      sort: (sort unless sort == 'date'),
      feature_ids: feature_ids.presence,
      distance: (distance if distance_active?),
    }.compact
  end
end
