# frozen_string_literal: true

class Competitions::Score::ListFactoriesController < CompetitionNestedController
  before_action :load_list_factory, only: %i[edit update destroy]
  authorize_resource :list_factory, class: Score::ListFactory

  before_action :redirect_to_edit, only: %i[new create]
  before_action :assign_disciplines, only: %i[new create]

  def create
    @list_factory = Score::ListFactory.new(
      session_id: session.id.to_s,
      type: 'Score::ListFactory',
      competition: @competition,
    )

    @list_factory.assign_attributes(list_factory_params)
    if @list_factory.save
      redirect_to action: :edit
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @list_factory.assign_attributes(list_factory_params)
    if @list_factory.save
      if @list_factory.status == :create
        @list_factory.destroy
        redirect_to competition_score_list_path(id: @list_factory.list.id)
      else
        redirect_to action: :edit
      end
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @list_factory.destroy
    redirect_to competition_score_lists_path, notice: 'Listerstellung wurde abgebrochen'
  end

  def copy_list
    @competition.score_list_factories.where(session_id: session.id.to_s).destroy_all
    list = @competition.score_lists.find(params[:list_id])

    factory = Score::ListFactories::TrackChange.create!(
      competition: @competition,
      session_id: session.id.to_s,
      discipline_id: list.assessments.first.discipline_id,
      next_step: :assessments,
      show_best_of_run: list.show_best_of_run,
      separate_target_times: list.separate_target_times,
    )
    factory.update!(next_step: :names, assessments: list.assessments)
    factory.update!(next_step: :tracks, name: factory.default_name, shortcut: factory.default_shortcut)
    factory.update!(next_step: :results, track_count: list.track_count)
    factory.update!(next_step: :generator, results: list.results)

    redirect_to action: :edit
  end

  protected

  def assign_disciplines
    @factories = @competition.disciplines.where(id: @competition.assessments.select(:discipline_id))
                             .sort.map do |discipline|
      Score::ListFactory.new(competition: @competition, discipline:)
    end
  end

  def redirect_to_edit
    redirect_to(action: :edit) if @competition.score_list_factories.exists?(session_id: session.id.to_s)
  end

  def load_list_factory
    @list_factory = @competition.score_list_factories.find_by!(session_id: session.id.to_s)
  rescue ActiveRecord::RecordNotFound
    redirect_to action: :new
  end

  def list_factory_params
    params.require(:score_list_factory).permit(:discipline_id, :next_step, :name, :shortcut, :track_count, :hidden,
                                               :type, :before_result_id, :before_list_id, :best_count, :track,
                                               :separate_target_times, :single_competitors_first, :show_best_of_run,
                                               result_ids: [], assessment_ids: [], band_ids: [])
  end
end
