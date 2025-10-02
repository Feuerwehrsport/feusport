# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::ResultEntrySupport do
  let(:result_entry_class) do
    Class.new do
      include Score::ResultEntrySupport

      attr_accessor :time, :result_type
    end
  end
  let(:result_entry) { result_entry_class.new }

  describe '.second_time' do
    it 'assign edit time' do
      expect(result_entry.edit_second_time).to eq ''

      result_entry.edit_second_time = '12.12'
      expect(result_entry.edit_second_time).to eq '12.12'
      expect(result_entry.time).to eq 1212

      result_entry.edit_second_time = '12.02'
      expect(result_entry.edit_second_time).to eq '12.02'
      expect(result_entry.time).to eq 1202

      result_entry.edit_second_time = '12.20'
      expect(result_entry.edit_second_time).to eq '12.20'
      expect(result_entry.time).to eq 1220

      result_entry.edit_second_time = '9.20'
      expect(result_entry.edit_second_time).to eq '9.20'
      expect(result_entry.time).to eq 920

      result_entry.result_type = :waiting
      expect(result_entry.human_time).to eq ''
      expect(result_entry.long_human_time).to eq 'Ungültig'

      result_entry.result_type = :no_run
      expect(result_entry.human_time).to eq 'N'
      expect(result_entry.long_human_time).to eq 'Ungültig'

      result_entry.result_type = :invalid
      expect(result_entry.human_time).to eq 'o.W.'
      expect(result_entry.long_human_time).to eq 'Ungültig'

      result_entry.result_type = :valid
      expect(result_entry.human_time).to eq '9,20'
      expect(result_entry.long_human_time).to eq '9,20 s'
    end
  end
end
