# frozen_string_literal: true

module AssessmentRequestHelper
  def person_short_type(request, html: true)
    if request.group_competitor?
      competitor_order_short_type(:group_competitor, request.group_competitor_order)
    elsif request.single_competitor?
      competitor_order_short_type(:single_competitor, request.single_competitor_order)
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

  private

  def competitor_order_short_type(type, competitor_order)
    if competitor_order.to_i.zero?
      I18n.t("assessment_types.#{type}_short")
    else
      I18n.t("assessment_types.#{type}_short_order", competitor_order:)
    end
  end
end
