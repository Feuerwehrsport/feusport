# frozen_string_literal: true

class Competitions::Score::CompetitionResultsController < CompetitionNestedController
  default_resource resource_class: Score::CompetitionResult, through_association: :score_competition_results

  def index
    send_pdf(Exports::Pdf::Score::CompetitionResults, args: [@competition, @competition_results.sort]) && return
    send_xlsx(Exports::Xlsx::Score::CompetitionResults, args: [@competition, @competition_results.sort]) && return
  end

  def show
    send_pdf(Exports::Pdf::Score::CompetitionResults, args: [@competition, [@competition_result]]) && return
    send_xlsx(Exports::Xlsx::Score::CompetitionResults, args: [@competition, [@competition_result]]) && return

    redirect_to action: :index
  end

  def create
    @competition_result.assign_attributes(competition_result_params)
    if @competition_result.save
      redirect_to competition_score_competition_results_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @competition_result.assign_attributes(competition_result_params)
    if @competition_result.save
      redirect_to competition_score_competition_results_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @competition_result.destroy
    redirect_to competition_score_competition_results_path, notice: :deleted
  end

  protected

  def competition_result_params
    params.require(:score_competition_result).permit(:name, :result_type, :hidden, result_ids: [])
  end
end
