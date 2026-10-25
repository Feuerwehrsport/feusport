# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScoreResultChannel do
  let(:competition) { create(:competition) }
  let(:result) { create(:score_result, competition:) }

  describe '#subscribed' do
    it 'streams the public result to visitors and the full result to admins' do
      stub_connection(current_user: nil, session: {})
      subscribe(score_result_id: result.id)
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("score_result_#{result.id}")

      stub_connection(current_user: competition.users.first, session: {})
      subscribe(score_result_id: result.id)
      expect(subscription).to have_stream_from("score_result_#{result.id}_admin")
    end

    it 'rejects invisible competitions and unknown results for visitors' do
      stub_connection(current_user: nil, session: {})
      subscribe(score_result_id: SecureRandom.uuid)
      expect(subscription).to be_rejected

      competition.update!(visible: false)
      subscribe(score_result_id: result.id)
      expect(subscription).to be_rejected
    end
  end

  describe ScoreResultChannel::Updater do
    describe '#perform' do
      it 'broadcasts rendered result' do
        expect do
          described_class.perform_now(result)
        end.to(have_broadcasted_to("score_result_#{result.id}").with do |data|
          expect(data['html']).to include('Keine Einträge gefunden')
        end)
      end

      it 'stops sending to visitors when the competition is invisible' do
        competition.update!(visible: false)

        expect do
          expect do
            described_class.perform_now(result)
          end.not_to have_broadcasted_to("score_result_#{result.id}")
        end.to have_broadcasted_to("score_result_#{result.id}_admin")
      end

      it 'includes hidden lists only in the admin stream' do
        person = create(:person, competition:, band: result.assessment.band, last_name: 'Versteckt')
        create_score_list(result, { person => 1500 }).update!(hidden_results: true)

        expect do
          expect do
            described_class.perform_now(result)
          end.to(have_broadcasted_to("score_result_#{result.id}").with do |data|
                   expect(data['html']).not_to include('Versteckt')
                 end)
        end.to(have_broadcasted_to("score_result_#{result.id}_admin").with do |data|
                 expect(data['html']).to include('Versteckt')
               end)
      end
    end

    describe '.safe_perform_later' do
      it 'enqueues job with test adapter' do
        expect do
          described_class.safe_perform_later(result)
        end.to have_enqueued_job(described_class).with(result)
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
          other_result = create(:score_result, competition:, assessment: result.assessment)

          described_class.safe_perform_later(result)
          described_class.safe_perform_later(other_result)
          expect(SolidQueue::Job.where(class_name: described_class.name).count).to eq 2

          described_class.safe_perform_later(result)
          jobs = SolidQueue::Job.where(class_name: described_class.name)
          expect(jobs.count).to eq 2
          expect(jobs.map { |job| job.arguments['arguments'].first['_aj_globalid'] }).to contain_exactly(
            result.to_global_id.to_s, other_result.to_global_id.to_s
          )
        end
      end
    end
  end
end
