# frozen_string_literal: true

# Einladungen gelten nur, solange sie nicht abgelaufen sind und der Absender
# sie jetzt noch verschicken dürfte (Zugriff entzogen, Wettkampf gesperrt, Anmeldeschluss).
module InvitationValidity
  extend ActiveSupport::Concern

  EXPIRES_IN = 30.days
  # Danach werden Einladungen ohne Hinweis gelöscht (CleanupJob)
  DELETE_AFTER = EXPIRES_IN * 2

  included do
    scope :deletable, -> { where(created_at: ...DELETE_AFTER.ago) }
  end

  def expires_at
    created_at + EXPIRES_IN
  end

  def expired?
    expires_at < Time.current
  end

  def sender_allowed?
    Ability.new(sender).can?(:create, self)
  end

  # :valid, :expired oder :revoked (Absender dürfte sie nicht mehr verschicken)
  def validity_status
    return :expired if expired?
    return :revoked unless sender_allowed?

    :valid
  end

  class CleanupJob < ApplicationJob
    def perform
      UserAccessRequest.deletable.delete_all
      UserTeamAccessRequest.deletable.delete_all
    end
  end
end
