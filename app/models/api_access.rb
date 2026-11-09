# frozen_string_literal: true

# Zugang für ein Gerät (z. B. Stoppuhr) zur REST-API eines Wettkampfs.
# Das Gerät tauscht einen kurz gültigen Code gegen einen Token, siehe Api::V1::PairingsController.
# == Schema Information
#
# Table name: api_accesses
#
#  id                      :uuid             not null, primary key
#  device_name             :string(100)
#  last_used_at            :datetime
#  name                    :string(50)       not null
#  paired_at               :datetime
#  pairing_code            :string(8)
#  pairing_code_expires_at :datetime
#  permission              :integer          default("results"), not null
#  score_list_ids          :uuid             default([]), not null, is an Array
#  token_digest            :string(64)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  competition_id          :uuid             not null
#
# Indexes
#
#  index_api_accesses_on_competition_id           (competition_id)
#  index_api_accesses_on_competition_id_and_name  (competition_id,name) UNIQUE
#  index_api_accesses_on_pairing_code             (pairing_code) UNIQUE
#  index_api_accesses_on_token_digest             (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class ApiAccess < ApplicationRecord
  include SortableByName

  PERMISSIONS = { results: 1, selected_results: 2 }.freeze
  PAIRING_CODE_DIGITS = 8
  PAIRING_CODE_VALIDITY = 15.minutes
  TOKEN_VALIDITY_AFTER_COMPETITION = 7.days
  LAST_USED_PRECISION = 1.minute

  belongs_to :competition
  enum :permission, PERMISSIONS, scopes: false, prefix: true

  include SelectableScoreLists

  schema_validations

  before_create :assign_pairing_code

  scope :with_valid_pairing_code, -> { where(pairing_code_expires_at: Time.current..) }

  # Klartext des Tokens, nur direkt nach dem Koppeln verfügbar
  attr_reader :token

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  # Tauscht den Code gegen einen Token. Die Sperre stellt sicher, dass ein Code nur einmal funktioniert.
  def self.pair(code, device_name: nil)
    transaction do
      access = with_valid_pairing_code.lock.find_by(pairing_code: code.to_s)
      next unless access&.active?

      access.pair(device_name)
      access
    end
  end

  def self.authenticate(token)
    access = find_by(token_digest: digest(token))
    access if access&.active?
  end

  def active?
    !competition.locked? && token_expires_at.future?
  end

  def token_expires_at
    (competition.date + TOKEN_VALIDITY_AFTER_COMPETITION).end_of_day
  end

  def paired?
    token_digest.present?
  end

  def pairing_code_valid?
    pairing_code.present? && pairing_code_expires_at.future?
  end

  # Ohne Validierung: Eine durch gelöschte Startlisten leere Auswahl darf das Koppeln nicht abstürzen lassen
  def pair(device_name)
    @token = SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest(@token)
    self.device_name = device_name.to_s.first(100).presence
    self.pairing_code = nil
    self.pairing_code_expires_at = nil
    self.paired_at = Time.current
    save!(validate: false)
  end

  def regenerate_pairing_code!
    assign_pairing_code
    save!(validate: false)
  end

  def record_usage
    return if last_used_at&.after?(LAST_USED_PRECISION.ago)

    update_column(:last_used_at, Time.current)
  end

  private

  def assign_pairing_code
    self.pairing_code = loop do
      code = SecureRandom.random_number(10**PAIRING_CODE_DIGITS).to_s.rjust(PAIRING_CODE_DIGITS, '0')
      break code unless self.class.exists?(pairing_code: code)
    end
    self.pairing_code_expires_at = PAIRING_CODE_VALIDITY.from_now
  end
end
