# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScoreListChannel do
  let(:competition) { create(:competition) }
  let(:list) { create(:score_list, competition:, track_count: 2) }

  describe '#subscribed' do
    it 'streams from editable and non editable list streams' do
      subscribe(score_list_id: list.id, editable: true)
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("score_list_#{list.id}_editable_true")

      subscribe(score_list_id: list.id, editable: false)
      expect(subscription).to have_stream_from("score_list_#{list.id}_editable_false")
    end
  end

  describe ScoreListChannel::Updater do
    describe '#perform' do
      let!(:entry1) { create(:score_list_entry, list:, competition:, track: 1, run: 1) }
      let!(:entry2) { create(:score_list_entry, list:, competition:, track: 2, run: 2, entity: entry1.entity) }

      it 'broadcasts empty tracks without run' do
        expect do
          expect do
            described_class.perform_now(list, tab_session_id: 'tab-1')
          end.to have_broadcasted_to("score_list_#{list.id}_editable_false")
            .with(run: nil, tab_session_id: 'tab-1', tracks: {})
        end.to have_broadcasted_to("score_list_#{list.id}_editable_true")
          .with(run: nil, tab_session_id: 'tab-1', tracks: {})
      end

      it 'broadcasts rendered entries of given run' do
        broadcasts = {}
        allow(ActionCable.server).to receive(:broadcast) { |stream, data| broadcasts[stream] = data }

        described_class.perform_now(list, tab_session_id: 'tab-2', run: 1)

        not_editable = broadcasts["score_list_#{list.id}_editable_false"]
        editable = broadcasts["score_list_#{list.id}_editable_true"]

        expect(not_editable[:run]).to eq 1
        expect(not_editable[:tab_session_id]).to eq 'tab-2'
        expect(not_editable[:tracks].keys).to eq [entry1.id]
        expect(editable[:tracks].keys).to eq [entry1.id]

        expect(not_editable[:tracks][entry1.id]).not_to include('Zeiten bearbeiten')
        expect(editable[:tracks][entry1.id]).to include('Zeiten bearbeiten')
      end
    end

    describe '.safe_perform_later' do
      it 'enqueues job with test adapter' do
        expect do
          described_class.safe_perform_later(list, run: 1, tab_session_id: 'tab')
        end.to have_enqueued_job(described_class).with(list, run: 1, tab_session_id: 'tab')
      end

      context 'with solid queue adapter' do
        around do |example|
          old_adapter = described_class.queue_adapter
          described_class.queue_adapter = ActiveJob::QueueAdapters::SolidQueueAdapter.new
          example.run
        ensure
          described_class.queue_adapter = old_adapter
        end

        it 'discards older unfinished jobs with same arguments' do
          described_class.safe_perform_later(list, run: 1, tab_session_id: 'tab')
          described_class.safe_perform_later(list, run: 2, tab_session_id: 'tab')
          jobs = SolidQueue::Job.where(class_name: described_class.name)
          expect(jobs.count).to eq 2

          described_class.safe_perform_later(list, run: 1, tab_session_id: 'tab')
          jobs = SolidQueue::Job.where(class_name: described_class.name)
          expect(jobs.count).to eq 2
          expect(jobs.map { |job| job.arguments['arguments'].last['run'] }).to contain_exactly(1, 2)
        end
      end
    end
  end
end
