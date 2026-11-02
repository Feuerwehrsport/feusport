# frozen_string_literal: true

# == Schema Information
#
# Table name: circular_mails
#
#  id               :uuid             not null, primary key
#  message          :text             not null
#  recipients_count :integer          default(0), not null
#  subject          :string(200)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  competition_id   :uuid             not null
#  user_id          :uuid             not null
#
# Indexes
#
#  index_circular_mails_on_competition_id  (competition_id)
#  index_circular_mails_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (user_id => users.id)
#
# Rundmail eines Admins an alle Nutzer, die Mannschaften oder Wettkämpfer zum Wettkampf angemeldet haben
class CircularMail < ApplicationRecord
  belongs_to :competition
  belongs_to :user

  schema_validations
  validate :recipients_present, on: :create

  before_create { self.recipients_count = recipients.count }

  def recipients
    User.where(id: UserTeamAccess.where(competition:).select(:user_id))
        .or(User.where(id: UserPersonAccess.where(competition:).select(:user_id)))
        .order(:name)
  end

  private

  def recipients_present
    return if recipients.exists?

    errors.add(:base, 'Es gibt noch keine angemeldeten Mannschaften oder Wettkämpfer mit Nutzerkonto.')
  end
end
