# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  schema_validations

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
