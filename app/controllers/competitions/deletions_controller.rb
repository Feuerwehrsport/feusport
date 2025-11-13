# frozen_string_literal: true

class Competitions::DeletionsController < CompetitionNestedController
  def new
    @deletion = Competitions::Deletion.new(competition: @competition)
  end

  def create
    @deletion = Competitions::Deletion.new(competition: @competition)
    @deletion.assign_attributes(deletion_params)
    if @deletion.save
      redirect_to root_path, notice: :deleted
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def deletion_params
    params.require(:competitions_deletion).permit(:confirm)
  end
end
