# frozen_string_literal: true

class Competitions::Score::ListConditionsController < CompetitionNestedController
  default_resource resource_class: Score::ListCondition, through_association: :score_list_conditions
  helper_method :redirect_url, :possible_assessments

  def create
    @list_condition.assign_attributes(list_condition_params)
    if @list_condition.save
      redirect_to_index notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @list_condition.assign_attributes(list_condition_params)
    if @list_condition.save
      redirect_to_index notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @list_condition.destroy
    redirect_to_index notice: :deleted
  end

  protected

  def list_condition_params
    params.require(:score_list_condition).permit(
      :track, :list_id, :factory_id, assessment_ids: []
    )
  end

  def assign_new_resource
    super
    resource_instance.list = @competition.score_lists.find(params[:list_id]) if params[:list_id].present?
    return if params[:list_factory_id].blank?

    resource_instance.factory = @competition.score_list_factories.find(params[:list_factory_id])
  end

  def possible_assessments
    (@list_condition&.factory || @competition).assessments.sort
  end

  def redirect_to_index(notice:)
    redirect_to redirect_url, notice:
  end

  def redirect_url
    if @list_condition.list.present?
      list_conditions_competition_score_list_path(id: @list_condition.list_id)
    else
      edit_competition_score_list_factories_path
    end
  end
end
