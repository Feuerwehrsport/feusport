# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::Run do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let(:assessment) { create(:assessment, competition:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:person1) { create(:person, :generated, competition:, band:) }
  let(:person2) { create(:person, :generated, competition:, band:) }
  let!(:list) { create_score_list(result, person1 => :waiting, person2 => :waiting) }
  let(:run) { described_class.new(list:, run_number: 1) }

  it 'raises when run does not exist' do
    expect { described_class.new(list:, run_number: 5) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe '#update' do
    let(:attributes) do
      { list_entries_attributes: {
        '0' => { track: '1', result_type: 'valid', edit_second_time: '19.12' },
        '1' => { track: '2', result_type: 'invalid' },
      } }
    end

    it 'updates all entries of run' do
      expect(run.name).to eq "#{list.name} (Lauf 1)"
      expect(run.update(attributes)).to be true

      expect(list.entries.find_by(track: 1)).to have_attributes(result_type: :valid, time: 1912)
      expect(list.entries.find_by(track: 2)).to have_attributes(result_type: :invalid)
    end

    it 'returns false when saving is rolled back' do
      allow(run.list_entries.load.first).to receive(:save!).and_raise(ActiveRecord::Rollback)

      expect(run.update(attributes)).to be false
      expect(list.entries.where(result_type: :waiting).count).to eq 2
    end
  end
end
