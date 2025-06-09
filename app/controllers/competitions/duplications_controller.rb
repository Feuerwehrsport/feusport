# frozen_string_literal: true

class Competitions::DuplicationsController < CompetitionNestedController
  before_action :check_preset_ran
  before_action :assign_duplication

  def create
    if @duplication.save
      redirect_to competition_show_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_entity
    end
  end

  protected

  def duplication_params
    params.require(:duplication).permit(
      :confirm, :duplicate_from_id
    )
  end

  def check_preset_ran
    return unless @competition.preset_ran?

    redirect_to competition_show_path, alert: 'Es wurde bereits eine Vorlage gewählt.'
  end

  def assign_duplication
    @duplication = Competitions::Duplication.new(competition: @competition)
    @duplication.assign_attributes(duplication_params) if params[:duplication].present?
    if @duplication.duplicate_from.nil?
      redirect_to competition_presets_path
      return
    end
    authorize!(:create, @duplication)
  end
end
