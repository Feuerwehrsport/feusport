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

  describe '.second_time=' do
    it 'parses minutes and seconds' do
      result_entry.second_time = '1:02,34'
      expect(result_entry.time).to eq 6234

      result_entry.second_time = '2:05.3'
      expect(result_entry.time).to eq 12_503
    end

    it 'parses one decimal place' do
      result_entry.second_time = '22,5'
      expect(result_entry.time).to eq 2250
    end

    it 'parses whole seconds' do
      result_entry.second_time = '23'
      expect(result_entry.time).to eq 2300
    end
  end

  describe '#target_times_as_data' do
    let(:result_entry_class) do
      Class.new do
        include Score::ResultEntrySupport

        attr_accessor :time, :result_type, :time_left_target, :time_right_target

        edit_time(:time_left_target)
        edit_time(:time_right_target)
      end
    end

    before do
      result_entry.time_left_target = 2012
      result_entry.time_right_target = 2133
    end

    it 'returns joined target times' do
      expect(result_entry.target_times_as_data).to eq 'L: 20,12, R: 21,33'
    end

    it 'skips missing target times' do
      result_entry.time_right_target = nil
      expect(result_entry.target_times_as_data).to eq 'L: 20,12'
    end

    it 'returns pdf cell data' do
      expect(result_entry.target_times_as_data(pdf: true, hint_size: 8)).to eq(
        content: "<font size='8'>L: 20,12<br/>R: 21,33</font>",
        inline_format: true, padding: [0, 0, 3, 0], valign: :center
      )
    end
  end
end
