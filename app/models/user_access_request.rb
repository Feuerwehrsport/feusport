# frozen_string_literal: true

# == Schema Information
#
# Table name: user_access_requests
#
#  id             :uuid             not null, primary key
#  drop_myself    :boolean          default(FALSE), not null
#  email          :string(200)      not null
#  text           :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  sender_id      :uuid             not null
#
# Indexes
#
#  index_user_access_requests_on_competition_id  (competition_id)
#  index_user_access_requests_on_sender_id       (sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (sender_id => users.id)
#
class UserAccessRequest < ApplicationRecord
  belongs_to :competition, touch: true
  belongs_to :sender, class_name: 'User'

  auto_strip_attributes :email, :text

  schema_validations
  validates :email, 'valid_email_2/email': Rails.configuration.x.email_validation

  def connect(user)
    competition.user_accesses.create!(user:)
    competition.user_accesses.where(user: sender).destroy_all if drop_myself?
    destroy
  end
end
