# frozen_string_literal: true

class Competitions::Certificates::ImportsController < CompetitionNestedController
  before_action :assign_new_resource
  def create
    @certificates_import.assign_attributes(import_params)
    if @certificates_import.save
      redirect_to competition_certificates_template_path(id: @certificates_import.duplicate.id), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def import_params
    return {} unless params.key?(:certificates_import)

    params.require(:certificates_import).permit(
      :template_id,
    )
  end

  def assign_new_resource
    @selectable_templates = Certificates::Template.importable(current_ability)
                                                  .includes(:competition)
                                                  .reorder('competitions.date' => :desc, 'competitions.name' => :asc,
                                                           'name' => :asc)
    @certificates_import = Certificates::Import.new(competition: @competition,
                                                    selectable_templates: @selectable_templates)
    authorize!(:show, @certificates_import)
  end
end
