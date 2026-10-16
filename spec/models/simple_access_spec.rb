# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SimpleAccess do
  let(:competition) { create(:competition) }

  describe 'password' do
    it 'requires at least 8 characters for new passwords' do
      access = described_class.new(competition:, name: 'Admin', password: 'kurz123')
      expect(access).not_to be_valid
      expect(access.errors.details[:password]).to include(a_hash_including(error: :too_short))

      access.password = 'lang1234'
      expect(access).to be_valid
    end

    it 'keeps existing short passwords valid' do
      access = described_class.new(competition:, name: 'Admin', password: 'kurz')
      access.save!(validate: false)

      expect(described_class.find(access.id)).to be_valid
    end
  end
end
