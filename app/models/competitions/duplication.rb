# frozen_string_literal: true

class Competitions::Duplication
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :competition, :duplicate_from_id

  attribute :confirm, :boolean, default: false
  validates :confirm, acceptance: true

  def save
    return false unless valid?

    Competition.transaction do
      disciplines_trans = {}
      duplicate_from.disciplines.each do |discipline|
        next if discipline.key == 'zk'

        new_discipline = competition.disciplines.create!(discipline
          .attributes.except('id', 'competition_id', 'created_at', 'updated_at'))
        disciplines_trans[discipline.id] = new_discipline.id
      end

      bands_trans = {}
      duplicate_from.bands.each do |band|
        new_band = competition.bands.create!(band
          .attributes.except('id', 'competition_id', 'created_at', 'updated_at'))
        bands_trans[band.id] = new_band.id
      end

      assessments_trans = {}
      duplicate_from.assessments.each do |assessment|
        new_hash = assessment.attributes.except('id', 'competition_id', 'created_at', 'updated_at', 'discipline_id',
                                                'band_id')
        new_hash[:discipline_id] = disciplines_trans[assessment.discipline_id] || next
        new_hash[:band_id] = bands_trans[assessment.band_id]
        new_assessment = competition.assessments.create!(new_hash)
        assessments_trans[assessment.id] = new_assessment.id
      end

      score_results_trans = {}
      duplicate_from.score_results.each do |score_result|
        new_hash = score_result.attributes.except('id', 'competition_id', 'created_at', 'updated_at', 'assessment_id',
                                                  'date')
        new_hash[:assessment_id] = assessments_trans[score_result.assessment_id]
        new_score_result = competition.score_results.create!(new_hash)
        score_results_trans[score_result.id] = new_score_result.id
      end
      duplicate_from.score_results.each do |score_result|
        score_result.result_references.each do |result_reference|
          Score::ResultReference.create!(result_id: score_results_trans[result_reference.result_id],
                                         multi_result_id: score_results_trans[result_reference.multi_result_id])
        end
      end

      duplicate_from.score_competition_results.each do |score_competition_result|
        new_score_competition_result = competition.score_competition_results.create!(score_competition_result
          .attributes.except('id', 'competition_id', 'created_at', 'updated_at'))
        score_competition_result.result_references.each do |reference|
          Score::CompetitionResultReference.create!(result_id: score_results_trans[reference.result_id],
                                                    competition_result: new_score_competition_result)
        end
      end
      competition.update!(preset_ran: true)
    end
  end

  def duplicate_from
    return @duplicate_from if defined?(@duplicate_from)

    @duplicate_from = Competition.find_by(id: duplicate_from_id)
  end
end
