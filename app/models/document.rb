# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id             :uuid             not null, primary key
#  title          :string(200)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid
#
# Indexes
#
#  index_documents_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Document < ApplicationRecord
  belongs_to :competition, touch: true
  has_one_attached :file

  auto_strip_attributes :title

  schema_validations
  validates :file, presence: true,
                   blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'application/pdf'],
                           size_range: 1..(10.megabytes) }

  def self.find_idpart!(idpart)
    find_by!('id::varchar like ?', "#{idpart}%")
  end

  def idpart
    id.to_s.first(8)
  end
end
