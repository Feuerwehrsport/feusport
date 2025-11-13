# frozen_string_literal: true

class Competitions::DocumentsController < CompetitionNestedController
  default_resource

  def create
    @document.assign_attributes(document_params)
    if @document.save
      redirect_to competition_show_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @document.assign_attributes(document_params)
    if @document.save
      redirect_to competition_show_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @document.destroy
    redirect_to competition_show_path, notice: :deleted
  end

  def download
    document = @competition.documents.find_idpart!(params[:idpart])
    redirect_to(rails_blob_url(document.file))
  end

  def preview
    document = @competition.documents.find_idpart!(params[:idpart])
    redirect_to(document.file.representation(resize_to_limit: [100, 100]).processed.url)
  end

  def image
    document = @competition.documents.find_idpart!(params[:idpart])
    redirect_to(document.file.representation(resize_to_limit: [1000, 1000]).processed.url)
  end

  protected

  def document_params
    params.require(:document).permit(
      :file, :title
    )
  end
end
