# frozen_string_literal: true

module Certificates::StorageSupport
  def storage_support_get(position)
    case position.key
    when :team_name
      entity.is_a?(TeamRelay) ? entity&.full_name : entity&.team&.real_certificate_name
    when :person_name
      entity&.full_name
    when :person_bib_number
      entity.try(:bib_number)
    when :time_long
      result_entry.long_human_time(seconds: 'Sekunden', invalid: 'Ungültig') if respond_to?(:result_entry)
    when :time_very_long
      storage_support_time_very_long
    when :time_other_long
      storage_support_time_very_long('belegte ')
    when :time_short
      result_entry.long_human_time(seconds: 's', invalid: Firesport::INVALID_STRING) if respond_to?(:result_entry)
    when :time_without_seconds
      if respond_to?(:result_entry)
        result_entry.human_time.tr('N', '-').gsub(Firesport::INVALID_STRING, '-').delete('s').strip
      end
    when :rank
      "#{place}."
    when :rank_with_rank
      "#{place}. Platz"
    when :rank_with_rank2
      "den #{place}. Platz"
    when :rank_without_dot
      place
    when :assessment
      result&.try(:assessment)&.forced_name.presence || result&.try(:assessment)&.discipline&.name.presence ||
        result&.name
    when :result_name
      result&.name
    when :assessment_with_gender
      result&.try(:assessment)&.name.presence || result&.name
    when :gender
      storage_support_band
    when :date
      I18n.l(result.try(:date) || competition.date)
    when :place
      competition.place
    when :competition_name
      competition.name
    when :points
      points if respond_to?(:points)
    when :points_with_points
      I18n.t('certificates.lists.export.points', count: points) if respond_to?(:points)
    when :text
      position.text
    end
  end

  private

  def storage_support_time_very_long(prefix = '')
    return unless respond_to?(:result_entry)

    if result_entry.result_valid?
      "#{prefix}mit einer Zeit von #{result_entry.long_human_time(seconds: 'Sekunden', invalid: 'Ungültig')}"
    else
      "#{prefix}mit einer ungültigen Zeit"
    end
  end

  def storage_support_band
    if result.respond_to?(:band)
      result&.band&.name
    elsif result.respond_to?(:assessment)
      result.assessment&.band&.name
    end
  end
end
