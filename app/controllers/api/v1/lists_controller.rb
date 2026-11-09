# frozen_string_literal: true

class Api::V1::ListsController < Api::V1::BaseController
  def index
    render json: { lists: accessible_lists.map { |list| list_json(list) } }
  end

  def show
    list = accessible_lists.find(params[:id])
    entries = list.entries.includes(:entity, assessment: :band)
    entries = entries.where(run: params[:run]) if params[:run].present?
    render json: list_json(list).merge(entries: entries.map(&:api_json))
  end

  private

  def list_json(list)
    list.slice(:id, :name, :track_count, :separate_target_times)
  end
end
