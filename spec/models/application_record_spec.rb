# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord do
  describe '#validate_dates' do
    let(:competition) { build(:competition) }

    it 'accepts dates in valid range' do
      competition.date = Date.new(1850, 1, 2)
      expect(competition).to be_valid
      competition.date = Date.new(2150, 12, 31)
      expect(competition).to be_valid
    end

    it 'rejects dates outside valid range' do
      competition.date = Date.new(1849, 12, 31)
      expect(competition).not_to be_valid
      expect(competition.errors.details[:date]).to include(error: :year_not_valid)

      competition.date = Date.new(2151, 1, 1)
      expect(competition).not_to be_valid
      expect(competition.errors.details[:date]).to include(error: :year_not_valid)
    end

    it 'rejects datetimes outside valid range' do
      competition.created_at = Time.zone.local(3000, 1, 1, 12, 0)
      expect(competition).not_to be_valid
      expect(competition.errors.details[:created_at]).to include(error: :year_not_valid)
    end
  end
end
