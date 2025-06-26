# frozen_string_literal: true

module Score::ListFactoryDefaults
  def possible_assessments
    Assessment.where(discipline:).sort
  end

  def possible_results
    Score::Result.where(id: assessments.joins(:results).pluck('score_results.id')).sort
  end

  def possible_before_results
    Score::Result.where(id: assessments.joins(:results).pluck('score_results.id')).sort
  end

  def possible_before_lists
    Score::List.where(id: assessments.joins(:lists).pluck('score_lists.id')).sort
  end

  def possible_bands
    Band.where(id: assessments.select(:band_id)).sort
  end

  def default_shortcut
    shortcut.presence || begin
      if discipline.like_fire_relay?
        'Lauf'
      else
        "Lauf #{default_run}"
      end
    end
  end

  def default_track_count
    track_count.presence || 2
  end

  def default_results
    results.presence || possible_results
  end

  def default_type
    type.presence || possible_types.first
  end

  def default_before_list
    before_list.presence || possible_before_lists.first
  end

  def default_before_result
    before_result.presence || possible_before_results.first
  end

  def default_best_count
    best_count.presence || 30
  end

  protected

  def default_main_name
    @default_main_name ||= assessments.one? ? assessments.first.name : discipline.name
  end

  def default_run
    run = 1
    loop do
      break if competition.score_lists.where(name: "#{default_main_name} - Lauf #{run}").blank?

      run += 1
    end
    run
  end
end
