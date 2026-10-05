# frozen_string_literal: true

module AssessmentRequestHelper
  def person_short_type(request, html: true)
    if request.group_competitor?
      I18n.t('assessment_types.group_competitor_short_order',
             competitor_order: request.group_competitor_order)
    elsif request.single_competitor?
      I18n.t('assessment_types.single_competitor_short_order',
             competitor_order: request.single_competitor_order)
    elsif request.out_of_competition?
      I18n.t('assessment_types.out_of_competition_short')
    elsif request.competitor?
      case request.assessment.discipline.key
      when 'fs'
        AssessmentRequest.fs_names[request.competitor_order]
      when 'la', 'gs'
        arr = AssessmentRequest.short_names[request.assessment.discipline.key][request.competitor_order] || []
        if html
          arr[1] = tag.span(arr[1], class: 'small') if arr[1]
          safe_join(arr)
        elsif arr[1]
          arr[1]
        else
          arr[0]
        end
      end
    end
  end

  def quick_assessment_change_link(person, assessment)
    tag.div(
      tag.div(
        class: 'quick-assessment-change-link far fa-edit',
        data: { url:
          edit_assessment_requests_competition_person_path(id: person.id,
                                                           assessment_id: assessment.id,
                                                           return_to: 'team') },
      ),
      class: 'float-end',
    )
  end
end
