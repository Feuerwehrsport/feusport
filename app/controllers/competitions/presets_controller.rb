# frozen_string_literal: true

class Competitions::PresetsController < CompetitionNestedController
  before_action :check_preset_ran
  before_action :assign_preset, only: %i[edit update]

  def index; end

  def update
    @preset.assign_attributes(preset_params) if params[:preset].present?
    if @preset.save
      redirect_to competition_show_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def preset_params
    params.require(:preset).permit(
      :selected_assessments, selected_bands: [], selected_disciplines: []
    )
  end

  def check_preset_ran
    return unless @competition.preset_ran?

    redirect_to competition_show_path, alert: 'Es wurde bereits eine Vorlage gewählt.'
  end

  def assign_preset
    @preset = Presets::Base.list[params[:id]&.to_sym].new(competition: @competition)
    @preset || raise(ActiveRecord::RecordNotFound)
    authorize!(:edit, @preset)
  end
end
