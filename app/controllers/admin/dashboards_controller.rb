# frozen_string_literal: true

class Admin::DashboardsController < AdminController
  def show
    @failed_jobs_count = SolidQueue::FailedExecution.count
    @import_pending = SolidQueue::Job.where(class_name: 'ImportSuggestionsJob', finished_at: nil)
                                     .where.missing(:failed_execution).exists?
    @last_import_at = FireSportStatistics::Person.maximum(:created_at)
    @open_publishings = FireSportStatistics::Publishing.where(published_at: nil)
                                                       .includes(:competition, :user).reorder(:created_at)
  end

  def import
    ImportSuggestionsJob.perform_later
    redirect_to admin_root_path, notice: :import_started
  end

  def clear_cache
    Rails.cache.clear
    redirect_to admin_root_path, notice: :cache_cleared
  end

  def retry_publishings
    FireSportStatistics::Publishing::Worker.perform_later
    redirect_to admin_root_path, notice: :publishings_retried
  end
end
