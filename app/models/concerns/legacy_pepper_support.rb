# frozen_string_literal: true

# Der frühere Devise-Pepper stand im öffentlichen Repository und schützt deshalb nichts. Der neue kommt aus
# DEVISE_PEPPER. Alte Hashes werden beim nächsten erfolgreichen Login mit dem neuen Pepper neu gespeichert.
# Kann entfernt werden, sobald die verbliebenen alten Hashes keine Rolle mehr spielen (Betroffene nutzen dann
# "Passwort vergessen").
module LegacyPepperSupport
  extend ActiveSupport::Concern

  LEGACY_PEPPER = 'f78a95bacb2de3575446c4259f560df6f16111438ce7aad3b1b62e4b566d9241' \
                  '1bd32ce1cb3c925883b4351836a51655d9d131e8b84359602151910326dfa47a'

  def valid_password?(password)
    return true if super
    return false unless legacy_password?(password)

    # Ohne Callbacks: kein Passwort-geändert-Hinweis, kein updated_at
    update_column(:encrypted_password, password_digest(password))
    true
  rescue ::BCrypt::Errors::InvalidHash
    false
  end

  private

  # Wie Devise::Encryptor.compare, nur mit dem alten Pepper
  def legacy_password?(password)
    return false if encrypted_password.blank? || self.class.pepper == LEGACY_PEPPER

    bcrypt = ::BCrypt::Password.new(encrypted_password)
    Devise.secure_compare(::BCrypt::Engine.hash_secret("#{password}#{LEGACY_PEPPER}", bcrypt.salt), encrypted_password)
  end
end
