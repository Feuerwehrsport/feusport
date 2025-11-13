# frozen_string_literal: true

class Competitions::UnlockingsController < CompetitionNestedController
  def new
    authorize!(:unlock, @competition)
    @unlocking = Competitions::Unlocking.new(competition: @competition)
  end

  def create
    authorize!(:unlock, @competition)
    @unlocking = Competitions::Unlocking.new(competition: @competition)
    @unlocking.assign_attributes(unlocking_params)
    if @unlocking.save
      redirect_to competition_show_path(slug: @competition.slug, year: @competition.year), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def unlocking_params
    params.require(:competitions_unlocking).permit(:confirm)
  end
end
