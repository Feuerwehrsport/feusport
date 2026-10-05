# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssessmentRequestHelper do
  def request_double(type, discipline_key: 'la', **attrs)
    instance_double(
      AssessmentRequest,
      group_competitor?: type == :group_competitor,
      single_competitor?: type == :single_competitor,
      out_of_competition?: type == :out_of_competition,
      competitor?: type == :competitor,
      assessment: instance_double(Assessment, discipline: instance_double(Discipline, key: discipline_key)),
      **attrs,
    )
  end

  describe '#person_short_type' do
    it 'returns group competitor order' do
      expect(helper.person_short_type(request_double(:group_competitor, group_competitor_order: 3))).to eq 'M3'
    end

    it 'returns single competitor order' do
      expect(helper.person_short_type(request_double(:single_competitor, single_competitor_order: 2))).to eq 'E2'
    end

    it 'returns out of competition short' do
      expect(helper.person_short_type(request_double(:out_of_competition))).to eq 'A'
    end

    it 'returns fs names' do
      expect(helper.person_short_type(request_double(:competitor, discipline_key: 'fs',
                                                                  competitor_order: 5))).to eq 'B2'
    end

    it 'returns la names as html' do
      result = helper.person_short_type(request_double(:competitor, discipline_key: 'la', competitor_order: 0))
      expect(result).to eq '1<span class="small">(Ma)</span>'
      expect(result).to be_html_safe
    end

    it 'returns gs names without html' do
      expect(helper.person_short_type(request_double(:competitor, discipline_key: 'gs', competitor_order: 1),
                                      html: false)).to eq '(V)'
    end

    it 'returns first part if second part is missing' do
      allow(AssessmentRequest).to receive(:short_names).and_return('la' => [['9']])
      expect(helper.person_short_type(request_double(:competitor, discipline_key: 'la', competitor_order: 0),
                                      html: false)).to eq '9'
    end

    it 'returns empty values for unknown competitor order' do
      expect(helper.person_short_type(request_double(:competitor, discipline_key: 'la', competitor_order: 99)))
        .to eq ''
      expect(helper.person_short_type(request_double(:competitor, discipline_key: 'la', competitor_order: 99),
                                      html: false)).to be_nil
    end

    it 'returns nil for other disciplines' do
      expect(helper.person_short_type(request_double(:competitor, discipline_key: 'hl', competitor_order: 1))).to be_nil
    end

    it 'returns 0 without known assessment type' do
      expect(helper.person_short_type(request_double(nil))).to eq 0
    end
  end
end
