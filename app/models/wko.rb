# frozen_string_literal: true

# == Schema Information
#
# Table name: wkos
#
#  id             :uuid             not null, primary key
#  description_md :text             not null
#  name           :string(100)      not null
#  slug           :string(100)      not null
#  subtitle       :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_wkos_on_slug  (slug) UNIQUE
#
class Wko < ApplicationRecord
  has_one_attached :file

  auto_strip_attributes :slug, :name, :subtitle, :description_md

  schema_validations
  validates :file, presence: true, blob: { content_type: ['application/pdf'] }

  def self.current
    find_by(slug: '2023')
  end

  def description_html
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    markdown.render(description_md)
  end
end
