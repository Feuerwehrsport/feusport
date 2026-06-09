# frozen_string_literal: true

# == Schema Information
#
# Table name: snapshots
#
#  id             :uuid             not null, primary key
#  highlight      :boolean          default(FALSE), not null
#  processed      :boolean          default(FALSE), not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_snapshots_on_competition_id  (competition_id)
#  index_snapshots_on_highlight       (highlight)
#  index_snapshots_on_processed       (processed)
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
      end.to have_enqueued_job(Snapshot::VariantJob)
    end
  end

  describe 'Snapshot::VariantJob' do
    let(:snapshot) { create(:snapshot, :large_image, competition:) }

    it 'creates image variants' do
      expect do
        expect do
          Snapshot::VariantJob.perform_now(snapshot)
        end.to change(ActiveStorage::VariantRecord, :count).by(5)
      end.to have_enqueued_job(Snapshot::NginxVariantsJob)

      expect do
        Snapshot::RemoveVariantJob.perform_now(snapshot)
      end.to change(ActiveStorage::VariantRecord, :count).by(-5)
    end
  end

  describe 'Snapshot::NginxVariantsJob' do
    let(:snapshot) { create(:snapshot, competition:) }

    it 'creates image variants' do
      FileUtils.rm_rf(snapshot.nginx_base_dir)

      expect do
        Snapshot::NginxVariantsJob.perform_now(snapshot)
      end.to have_enqueued_job(Snapshot::RemoveVariantJob)

      expect(Dir["#{snapshot.nginx_base_dir}/*"].count).to eq 5

      snapshot.destroy

      expect(Dir["#{snapshot.nginx_base_dir}/*"].count).to eq 0
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

  describe 'Snapshot::ReminderJob' do
    it 'delivers mails to competitions without highligt' do
      expect do
        Snapshot::ReminderJob.perform_now
      end.to have_enqueued_job.with('CompetitionMailer', 'snapshot_reminder', 'deliver_now',
                                    { params: { competition: }, args: [] })

      competition.reload
      expect(competition.snapshot_reminder_sent).not_to be_nil

      expect do
        Snapshot::ReminderJob.perform_now
      end.not_to have_enqueued_job

      competition.update!(snapshot_reminder_sent: nil)
      snapshot = create(:snapshot, competition:, highlight: true)

      expect do
        Snapshot::ReminderJob.perform_now
      end.not_to have_enqueued_job

      competition.reload
      expect(competition.snapshot_reminder_sent).not_to be_nil
      competition.update!(snapshot_reminder_sent: nil)

      snapshot.update!(highlight: false)

      expect do
        Snapshot::ReminderJob.perform_now
      end.to have_enqueued_job
    end
  end
end
