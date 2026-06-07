# frozen_string_literal: true

# == Schema Information
#
# Table name: snapshots
#
#  id             :uuid             not null, primary key
#  highlight      :boolean          default(FALSE), not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_snapshots_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Snapshot do
  let(:competition) { create(:competition) }

  describe 'snapshot limit' do
    before do
      create_list(:snapshot, 15, competition:)
    end

    it 'rejects an 16th snapshot' do
      snapshot = build(:snapshot, competition:)

      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:file]).to be_present
    end

    it 'allows updating an existing snapshot' do
      snapshot = competition.snapshots.first

      snapshot.title = 'Neuer Titel'

      expect(snapshot).to be_valid
    end
  end

  describe 'callbacks' do
    it 'enqueues resize job after create' do
      expect do
        snapshot = create(:snapshot)
        expect(snapshot).to be_persisted
      end.to have_enqueued_job(Snapshot::ResizeJob)
    end
  end

  describe 'Snapshot::ResizeJob' do
    let(:snapshot) { create(:snapshot, :large_image, competition:) }

    it 'limits image dimensions' do
      Snapshot::ResizeJob.perform_now(snapshot)

      snapshot.reload

      metadata = snapshot.file.metadata
      expect(metadata['width']).to be <= 2000
      expect(metadata['height']).to be <= 2000
    end
  end

  describe 'only one highlight' do
    it 'resets highlight flag' do
      snapshot_one = create(:snapshot, competition:, highlight: true)
      expect(snapshot_one).to be_highlight

      snapshot_two = create(:snapshot, competition:, highlight: true)
      expect(snapshot_two).to be_highlight

      snapshot_one.reload
      expect(snapshot_one).not_to be_highlight
      expect(described_class.count).to eq 2
    end
  end
end
