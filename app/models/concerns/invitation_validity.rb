# frozen_string_literal: true

# Einladungen gelten nur, solange sie nicht abgelaufen sind und der Absender
# sie jetzt noch verschicken dürfte (Zugriff entzogen, Wettkampf gesperrt, Anmeldeschluss).
module InvitationValidity
  extend ActiveSupport::Concern

  EXPIRES_IN = 30.days

  def expired?
    created_at < EXPIRES_IN.ago
  end

  def sender_allowed?
    Ability.new(sender).can?(:create, self)
  end
end
