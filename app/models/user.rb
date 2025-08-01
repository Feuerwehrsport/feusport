# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  competition_manager    :boolean          default(FALSE), not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string(100)
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(100)
#  email                  :string(100)      not null
#  encrypted_password     :string(100)      not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(100)
#  locked_at              :datetime
#  name                   :string(100)      not null
#  phone_number           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string(100)
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string(100)
#  unlock_token           :string(100)
#  user_manager           :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
  include SortableByName

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  has_many :user_access_requests, class_name: 'UserAccessRequest', dependent: :destroy, foreign_key: :sender_id,
                                  inverse_of: :sender
  has_many :user_accesses, class_name: 'UserAccess', dependent: :destroy
  has_many :competitions, through: :user_accesses
  has_many :user_team_access_requests, class_name: 'UserTeamAccessRequest', dependent: :destroy,
                                       foreign_key: :sender_id, inverse_of: :sender
  has_many :user_team_accesses, class_name: 'UserTeamAccess', dependent: :destroy
  has_many :teams, through: :user_team_accesses

  has_many :user_person_accesses, class_name: 'UserPersonAccess', dependent: :destroy
  has_many :people, through: :user_person_accesses

  has_many :information_requests, dependent: :destroy

  auto_strip_attributes :name, :email, :phone_number

  schema_validations

  def friends
    user_ids = UserAccess.where(competition_id: competition_ids).pluck(:user_id) +
               UserTeamAccess.where(team_id: user_team_accesses.select(:team_id)).pluck(:user_id)
    User.where(id: user_ids).where.not(id:).order(:name)
  end

  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end
end
