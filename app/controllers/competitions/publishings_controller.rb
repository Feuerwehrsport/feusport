# frozen_string_literal: true

class Competitions::PublishingsController < CompetitionNestedController
  before_action :assign_new_resource

  def create
    @publishing.assign_attributes(publishing_params)
    if @publishing.save
      redirect_to competition_show_path, notice: :deleted
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def assign_new_resource
    authorize!(:edit, @competition)
    @publishing = Competitions::Publishing.new(competition: @competition, user: current_user)
  end

  def publishing_params
    params.require(:competitions_publishing).permit(:confirm, :hint)
  end
end
