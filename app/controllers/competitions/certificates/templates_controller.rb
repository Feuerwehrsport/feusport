# frozen_string_literal: true

class Competitions::Certificates::TemplatesController < CompetitionNestedController
  default_resource resource_class: Certificates::Template, through_association: :certificates_templates

  def show
    send_pdf(Exports::Pdf::Certificates::Export) do
      [@template, "Urkundenvorlage: #{@template.name}", [Certificates::Example.new], true]
    end
  end

  def duplicate
    new_template = @template.duplicate_to(@competition)
    flash[:info] = 'Duplikat erstellt'
    redirect_to action: :show, id: new_template.id
  end

  def remove_file
    @template.public_send(params[:type]).purge if params[:type].in?(%w[image font font2])
    redirect_to action: :show, id: params[:id]
  end

  def create
    @template.assign_attributes(template_params)
    if @template.save
      redirect_to competition_certificates_template_path(id: @template.id), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @template.assign_attributes(template_params)
    if @template.save
      redirect_to competition_certificates_template_path(id: @template.id), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @template.destroy
    redirect_to competition_certificates_templates_path, notice: :deleted
  end

  protected

  def template_params
    params.require(:certificates_template).permit(
      :name, :image, :font, :font2, :importable_for_me, :importable_for_others,
      text_fields_attributes: %i[left top width height size key font align text id color _destroy]
    )
  end
end
