# frozen_string_literal: true

class Competitions::ApiAccessesController < CompetitionNestedController
  default_resource resource_class: ApiAccess, through_association: :api_accesses

  def create
    @api_access.assign_attributes(api_access_params)
    if @api_access.save
      redirect_to competition_accesses_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    if @api_access.update(api_access_params)
      redirect_to competition_accesses_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def regenerate_code
    @api_access.regenerate_pairing_code!
    redirect_to competition_accesses_path, notice: :saved
  end

  def destroy
    @api_access.destroy
    redirect_to competition_accesses_path, notice: :deleted
  end

  protected

  def api_access_params
    params.require(:api_access).permit(:name, :permission, score_list_ids: [])
  end
end
