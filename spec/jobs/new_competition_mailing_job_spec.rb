# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewCompetitionMailingJob do
  include ActiveJob::TestHelper

  let(:organizer) { create(:user) }
  let(:din) { create(:feature, :din) }
  let(:tgl) { create(:feature, :tgl) }
  let!(:all_user) { create(:user, :other, want_mailing: :all) }
  let!(:filter_user) do
    create(:user, email: 'filter@meier.de', want_mailing: :by_filter, features: [tgl])
  end
  let!(:nothing_user) { create(:user, email: 'nothing@meier.de') }
  let!(:competition) do
    create(:competition, users: [organizer], date: 1.month.from_now.to_date, features: [din], visible: false)
  end

  def mail_recipients
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  def run_job
    ActionMailer::Base.deliveries.clear
    perform_enqueued_jobs { described_class.perform_now }
  end

  it 'informs about competitions published at least one day ago' do
    competition.update!(visible: true)
    run_job
    expect(mail_recipients).to be_empty
    expect(competition.reload.new_competition_mailing_sent_at).to be_nil

    competition.update!(published_at: 25.hours.ago)
    run_job
    expect(mail_recipients).to contain_exactly('other@meier.de')
    expect(competition.reload.new_competition_mailing_sent_at).to be_present

    run_job
    expect(mail_recipients).to be_empty

    tgl_competition = create(:competition, users: [organizer], name: 'TGL-Cup', date: 2.months.from_now.to_date,
                                           features: [tgl], published_at: 2.days.ago)
    run_job
    expect(mail_recipients).to contain_exactly('other@meier.de', 'filter@meier.de')
    expect(tgl_competition.reload.new_competition_mailing_sent_at).to be_present
  end

  it 'does not inform about past or todays competitions' do
    past = create(:competition, users: [organizer], name: 'Vorbei', date: 1.day.ago.to_date, published_at: 2.days.ago)
    today = create(:competition, users: [organizer], name: 'Heute', date: Date.current, published_at: 2.days.ago)
    run_job
    expect(mail_recipients).to be_empty
    expect(past.reload.new_competition_mailing_sent_at).to be_present
    expect(today.reload.new_competition_mailing_sent_at).to be_present
  end

  it 'does not inform about hidden competitions' do
    competition.update!(published_at: 2.days.ago)
    run_job
    expect(mail_recipients).to be_empty
    expect(competition.reload.new_competition_mailing_sent_at).to be_nil
  end

  it 'does not inform users about their own competitions' do
    competition.update!(visible: true, published_at: 2.days.ago, users: [all_user])
    run_job
    expect(mail_recipients).to be_empty
  end
end
