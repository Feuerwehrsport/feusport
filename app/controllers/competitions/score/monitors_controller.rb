# frozen_string_literal: true

class Competitions::Score::MonitorsController < CompetitionNestedController
  layout 'monitor'
  before_action :assign_monitor

  def show; end

  def content
    render partial: 'content', locals: { monitor: @monitor }
  end

  private

  def assign_monitor
    list_ids = params[:list_ids].is_a?(Array) ? params[:list_ids] : nil
    @monitor = Score::Monitor.new(@competition, list_ids:)
  end
end
