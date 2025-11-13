# frozen_string_literal: true

class Competitions::Score::ListsController < CompetitionNestedController
  default_resource resource_class: Score::List, through_association: :score_lists

  def destroy_entity
    @entries = @list.entries.where(id: params[:entry_id])
  end

  def edit_entity
    @entries = @list.entries.where(id: params[:entry_id])
    @possible_entities = possible_entities(only_not_present: false)
  end

  def select_entity
    @not_yet_present_entities = possible_entities(only_not_present: params[:all_entities].blank?)
  end

  def move
    return if params[:new_order].blank?

    order_params = params.require(:list).permit(:save, new_order: {})

    new_order = order_params[:new_order].to_h.values
    new_order.each_with_index do |entry_id, index|
      next if entry_id.nil?

      track = (index % @list.track_count) + 1
      run = (index / @list.track_count) + 1

      entry = @list.entries.find { |e| e.id == entry_id }
      entry.assign_attributes(track:, run:)
      entry.save if order_params[:save]
    end

    @list.errors.add(:base, :invalid) unless order_params[:save]
  end

  def show
    send_pdf(Exports::Pdf::Score::List, args: [@list, params[:more_columns].present?])
    send_xlsx(Exports::Xlsx::Score::List, args: [@list])
  end

  def edit_times
    authorize!(:edit_times, resource_instance)
  end

  def update
    @list.assign_attributes(list_params)
    @list.entries.reject(&:persisted?).each { |e| e.competition = @competition }
    if @list.save
      redirect_to competition_score_list_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      if @list.entries.reject(&:persisted?).present?
        params[:all_entities] = true
        select_entity
        render action: :select_entity, status: :unprocessable_content
      elsif list_params[:entries_attributes].present?
        render action: :edit_times, status: :unprocessable_content
      else
        render action: :edit, status: :unprocessable_content
      end
    end
  end

  def destroy
    @list.destroy
    redirect_to competition_score_lists_path, notice: :deleted
  end

  def list_conditions; end

  protected

  def list_params
    return {} unless params.key?(:score_list)

    editable_attributes = %i[
      id run track entity_id entity_type _destroy assessment_type assessment_id
    ]

    editable_attributes.push(:result_type, :result_type_before) if can?(:edit_result_types, Score::ListEntry)
    if can?(:edit_times, Score::ListEntry)
      editable_attributes.push(:edit_second_time, :edit_second_time_before,
                               :edit_second_time_left_target, :edit_second_time_left_target_before,
                               :edit_second_time_right_target, :edit_second_time_right_target_before)
    end

    params.require(:score_list).permit(:name, :shortcut, :date, :show_multiple_assessments, :hidden,
                                       :show_best_of_run, :starting_time_string,
                                       result_ids: [],
                                       assessment_ids: [],
                                       entries_attributes: editable_attributes)
  end

  def possible_entities(only_not_present:)
    if @list.assessments&.first&.like_fire_relay?
      @competition.teams.where(band: @list.assessments.map(&:band)).map do |team|
        TeamRelay.create_next_free_for(team, @list.entries.pluck(:entity_id))
      end
    else
      all = @list.discipline_klass.where(competition: @competition)
      all = all.where.not(id: @list.entries.pluck(:entity_id)) if only_not_present
      all.sort_by(&:full_name)
    end
  end
end
