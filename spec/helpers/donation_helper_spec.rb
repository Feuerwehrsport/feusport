# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DonationHelper do
  before { stub_const('DonationHelper::DONATION_IBAN', 'DE02120300000000202051') }

  it 'formats the iban and builds a girocode' do
    expect(helper.formatted_donation_iban).to eq 'DE02 1203 0000 0000 2020 51'

    payload = nil
    allow(RQRCode::QRCode).to(receive(:new).and_wrap_original { |m, data, **opts| m.call(payload = data, **opts) })
    expect(helper.donation_girocode).to start_with 'data:image/png;base64,'
    expect(payload).to eq "BCD\n002\n1\nSCT\n\nGeorg Limbach\nDE02120300000000202051\n\n\n\nSpende feusport.de"
  end
end
