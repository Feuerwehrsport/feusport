# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::AutoDeletion do
  before { travel_to Time.zone.parse('2026-06-15 04:00') }

  def competition(name, date, **)
    create(:competition, name:, date: Date.parse(date), visible: false, **)
  end

  describe 'Job' do
    it 'notifies first and deletes two weeks later' do
      old = competition('Alt', '2020-05-01')
      soon = competition('Bald', '2025-06-29')
      later = competition('Später', '2025-07-13')
      visible = competition('Sichtbar', '2020-05-01', visible: true)

      expect { described_class::Job.perform_now }
        .to have_enqueued_mail(CompetitionMailer, :deletion_notice).twice
      expect(old.reload.deletion_notified_at).to be_present
      expect(soon.reload.deletion_notified_at).to be_present
      expect(later.reload.deletion_notified_at).to be_nil
      expect(visible.reload.deletion_notified_at).to be_nil

      expect(described_class.deletion_date(old)).to eq Date.parse('2026-06-29')
      expect(described_class.deletion_date(soon)).to eq Date.parse('2026-06-29')

      travel_to(Time.zone.parse('2026-06-28 04:00'))
      expect { described_class::Job.perform_now }.not_to change(Competition, :count)

      travel_to(Time.zone.parse('2026-06-29 04:00'))
      expect { described_class::Job.perform_now }
        .to change(Competition, :count).by(-2)
        .and have_enqueued_mail(CompetitionMailer, :deletion_notice).once
      expect(Competition.pluck(:name)).to contain_exactly('Später', 'Sichtbar')
    end

    it 'keeps competitions which became visible' do
      old = competition('Alt', '2020-05-01')
      described_class::Job.perform_now

      old.reload.update!(visible: true)
      expect(old.reload.deletion_notified_at).to be_nil

      travel_to(Time.zone.parse('2026-07-30 04:00'))
      expect { described_class::Job.perform_now }.not_to change(Competition, :count)
    end
  end
end
