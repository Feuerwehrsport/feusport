# frozen_string_literal: true

module Taggable
  extend ActiveSupport::Concern

  included do
    before_validation :clean_tags
  end

  def include_tags?(other_tags)
    other_tags.all? { |tag| tags.include?(tag) }
  end

  def exclude_tags?(other_tags)
    tags.all? { |tag| other_tags.exclude?(tag) }
  end

  protected

  def clean_tags
    self.tags = (tags || []).select { |tag| tag.in?(band.public_send(:"#{self.class.name.downcase}_tags")) }
  end
end
