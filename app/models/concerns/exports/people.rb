# frozen_string_literal: true

module Exports::People
  include AssessmentRequestHelper

  def index_export_data(band)
    collection = band.people.sort

    assessments = Assessment.where(band:)

    headline = []
    headline.push('Nr.') if competition.show_bib_numbers?
    headline.push('Nachname', 'Vorname', 'Mannschaft')

    band.person_tags.each { |tag| headline.push(tag) }
    assessments.each do |assessment|
      full_name = assessment.name
      full_name = full_name.gsub(band.name, '').strip
      full_name = full_name.gsub(/\s*-\s*-\s*/, ' - ').strip
      full_name = full_name.gsub(/-\Z/, '').strip
      full_name = full_name.gsub(/\s*-\s*-\s*/, ' - ').strip
      full_name = full_name.gsub(/-\Z/, '').strip
      headline.push(full_name)
    end
    data = [headline]

    collection.each do |person|
      line = []
      line.push(person.bib_number) if competition.show_bib_numbers?
      line.push(person.last_name, person.first_name, person.team&.shortcut_name)
      band.person_tags.each { |tag| line.push(person.tags.include?(tag) ? 'X' : '') }
      assessments.each do |assessment|
        request = person.request_for(assessment)
        if request.present?
          line.push(person_short_type(request, html: false))
        else
          line.push('')
        end
      end
      data.push(line)
    end
    data
  end

  def export_title
    'Wettkämpfer'
  end
end
