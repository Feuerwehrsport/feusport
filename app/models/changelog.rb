# frozen_string_literal: true

# == Schema Information
#
# Table name: changelogs
#
#  id         :uuid             not null, primary key
#  date       :date             not null
#  md         :text             not null
#  title      :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Changelog < ApplicationRecord
  schema_validations

  def html
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    markdown.render(md)
  end
end
