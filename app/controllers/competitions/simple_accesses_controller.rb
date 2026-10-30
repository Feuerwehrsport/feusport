# frozen_string_literal: true

class Competitions::SimpleAccessesController < CompetitionNestedController
  default_resource resource_class: SimpleAccess, through_association: :simple_accesses

  def create
    @simple_access.assign_attributes(simple_access_params)
    if @simple_access.save
      redirect_to competition_accesses_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    if @simple_access.update(simple_access_params)
      redirect_to competition_accesses_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @simple_access.destroy
    redirect_to competition_accesses_path, notice: :deleted
  end

  protected

  def simple_access_params
    params.require(:simple_access).permit(
      :name, :password, :password_confirmation, :permission, score_list_ids: []
    )
  end
end
