# frozen_string_literal: true

module DonationHelper
  DONATION_RECIPIENT = 'Georg Limbach'
  DONATION_IBAN = 'DE31120300001029186259'
  DONATION_PURPOSE = 'Spende feusport.de'
  DONATION_PAYPAL_URL = 'https://paypal.me/georglimbach?country.x=DE&locale.x=de_DE'

  def donation_iban
    DONATION_IBAN
  end

  def formatted_donation_iban
    donation_iban.scan(/.{1,4}/).join(' ')
  end

  # GiroCode (EPC-QR-Code) ohne Betrag, den wählt man in der Banking-App selbst.
  def donation_girocode
    payload = ['BCD', '002', '1', 'SCT', '', DONATION_RECIPIENT, donation_iban, '', '', '', DONATION_PURPOSE]
    RQRCode::QRCode.new(payload.join("\n"), level: :m).as_png(size: 240).to_data_url
  end
end
