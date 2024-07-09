# frozen_string_literal: true

class Competitions::Score::ResultsController < CompetitionNestedController
  default_resource resource_class: Score::Result, through_association: :score_results

  def show
    send_pdf(Exports::Pdf::Score::Result, args: [@result, params[:only]]) && return
    send_xlsx(Exports::Xlsx::Score::Result, args: [@result]) && return

    @rows = @result.rows
    @out_of_competition_rows = @result.out_of_competition_rows
    @discipline = @result.discipline
    @group_result = Score::GroupResult.new(@result) if @result.group_assessment? && @discipline.single_discipline?
  end

  def create
    @result.assign_attributes(result_params)
    if params[:name_preview]
      @result.forced_name = nil
      render json: { name: @result.name }
    elsif @result.save
      redirect_to competition_score_result_path(id: @result.id), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    @result.assign_attributes(result_params)
    if params[:name_preview]
      @result.forced_name = nil
      render json: { name: @result.name }
    elsif @result.save
      redirect_to competition_score_result_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @result.destroy
    redirect_to competition_score_results_path, notice: :deleted
  end

  protected

  def result_params
    params.require(:score_result).permit(
      :forced_name, :assessment_id, :group_assessment, :date, :calculation_method,
      :group_score_count, :group_run_count,
      team_tags_included: [],
      team_tags_excluded: [],
      person_tags_included: [],
      person_tags_excluded: [],
      series_assessment_ids: []
    )
  end
end
