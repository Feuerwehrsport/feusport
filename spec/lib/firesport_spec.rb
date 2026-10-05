# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Firesport do
  describe Firesport::TimeInvalid do
    it 'detects valid and invalid times' do
      expect(Series::PersonParticipation.new(time: 2233).time_valid?).to be true
      expect(Series::PersonParticipation.new(time: 2233).time_invalid?).to be false
      expect(Series::TeamParticipation.new(time: Firesport::INVALID_TIME).time_valid?).to be false
      expect(Series::TeamParticipation.new(time: Firesport::INVALID_TIME).time_invalid?).to be true
    end

    it 'provides valid and invalid scopes' do
      expect(Series::PersonParticipation.valid.to_sql).to include('"time" != 99999999')
      expect(Series::PersonParticipation.invalid.to_sql).to include('"time" = 99999999')
    end
  end

  describe Firesport::Time do
    it 'formats second times' do
      expect(described_class.second_time(2233)).to eq '22,33'
      expect(described_class.second_time(-105)).to eq '-1,05'
      expect(described_class.second_time(nil)).to eq 'o.W.'
      expect(described_class.second_time(Float::NAN)).to eq 'o.W.'
      expect(described_class.second_time(Firesport::INVALID_TIME)).to eq 'o.W.'
    end
  end
end
