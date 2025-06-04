# frozen_string_literal: true

# == Schema Information
#
# Table name: information_requests
#
#  id             :uuid             not null, primary key
#  message        :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  user_id        :uuid             not null
#
# Indexes
#
#  index_information_requests_on_competition_id  (competition_id)
#  index_information_requests_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (user_id => users.id)
#
class InformationRequest < ApplicationRecord
  belongs_to :competition
  belongs_to :user

  schema_validations

  def possible?
    competition.visible? && competition.user_accesses.with_registration_mail_info.exists?
  end
end
