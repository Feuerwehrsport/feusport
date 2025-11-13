# frozen_string_literal: true

class Competitions::Score::RunsController < CompetitionNestedController
  before_action :assign_run

  def edit; end

  def update
    if @run.update(run_params)
      flash[:notice] = :saved
      redirect_to competition_score_list_path(id: params[:list_id], jump_to: "jump-run-#{params[:run]}")
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def assign_run
    @list = @competition.score_lists.find(params[:list_id])
    authorize!(:edit_times, @list)
    @run = Score::Run.new(list: @list, run_number: params[:run])
  end

  def run_params
    editable_attributes = %i[id track]

    editable_attributes.push(:result_type, :result_type_before) if can?(:edit_result_types, Score::ListEntry)
    if can?(:edit_times, Score::ListEntry)
      editable_attributes.push(:edit_second_time, :edit_second_time_before,
                               :edit_second_time_left_target, :edit_second_time_left_target_before,
                               :edit_second_time_right_target, :edit_second_time_right_target_before)
    end

    params.require(:score_run).permit(list_entries_attributes: editable_attributes)
  end
end
