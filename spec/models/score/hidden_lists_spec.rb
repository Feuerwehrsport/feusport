# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::Result do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let(:assessment) { create(:assessment, competition:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }

  let(:public_person) { create(:person, competition:, band:, first_name: 'Offen', last_name: 'Sichtbar') }
  let(:hidden_person) { create(:person, competition:, band:, first_name: 'Geheim', last_name: 'Versteckt') }

  let!(:public_list) { create_score_list(result, { public_person => 2000 }, 'Lauf 1') }
  let!(:hidden_list) do
    create_score_list(result, { hidden_person => 1500 }, 'Lauf 2').tap do |list|
      list.update!(shortcut: 'Geheim', hidden_results: true)
    end
  end

  def names(rows)
    rows.map { |row| row.entity.last_name }
  end

  describe Score::List do
    it 'is public only without hidden flags' do
      expect(public_list.results_public?).to be true
      expect(hidden_list.results_public?).to be false

      hidden_list.update!(hidden_results: false, hidden: true)
      expect(hidden_list.results_public?).to be false
    end
  end

  describe 'rows with hidden lists' do
    it 'ignores hidden lists by default' do
      expect(names(result.rows)).to eq ['Sichtbar']
      expect(result.shown_lists).to eq [public_list]
      expect(result.hidden_lists).to eq [hidden_list]
    end

    it 'includes hidden lists for admins' do
      result.include_hidden_lists = true
      expect(names(result.rows)).to eq %w[Versteckt Sichtbar]
      expect(result.shown_lists).to contain_exactly(public_list, hidden_list)
    end

    it 'treats hidden lists like hidden results' do
      hidden_list.update!(hidden_results: false, hidden: true)
      expect(names(described_class.find(result.id).rows)).to eq ['Sichtbar']
    end

    it 'passes the flag to multi results' do
      multi = described_class.create!(competition:, forced_name: 'Zweikampf', image_key: 'hl',
                                      multi_result_method: :best, results: [result])
      expect(names(multi.rows)).to eq ['Sichtbar']
      expect(multi.hidden_lists).to eq [hidden_list]

      multi = described_class.find(multi.id)
      multi.include_hidden_lists = true
      expect(names(multi.rows)).to eq %w[Versteckt Sichtbar]
    end

    it 'exports only shown lists' do
      export = Exports::Xlsx::Score::Result.new(result)
      expect(export.build_data_rows(result, true).first).not_to include('Geheim')

      admin_result = described_class.find(result.id)
      admin_result.include_hidden_lists = true
      expect(export.build_data_rows(admin_result, true).first).to include('Geheim (versteckt)')
    end
  end

  describe Score::CompetitionResult do
    it 'passes the flag to its results' do
      competition_result = create(:score_competition_result, competition:, results: [result])
      competition_result.include_hidden_lists = true
      competition_result.rows
      expect(competition_result.results.map(&:include_hidden_lists)).to eq [true]
      expect(competition_result.hidden_lists).to eq [hidden_list]
    end
  end

  describe Certificates::List do
    it 'always includes hidden lists' do
      certificates_list = described_class.new(competition:, score_result_id: result.id)
      expect(names(certificates_list.rows)).to eq %w[Versteckt Sichtbar]

      competition_result = create(:score_competition_result, competition:, results: [result])
      certificates_list = described_class.new(competition:, competition_result_id: competition_result.id)
      expect(certificates_list.competition_result.include_hidden_lists).to be true
    end
  end

  describe Score::ListFactories::Best do
    it 'uses hidden lists of the previous result' do
      factory = described_class.new(competition:, before_result: result)
      expect(names(factory.send(:result_rows))).to eq %w[Versteckt Sichtbar]
    end
  end

  describe Exports::ScoreLists do
    it 'leaves out times and targets when hidden' do
      export = Exports::Xlsx::Score::List.new(hidden_list, true)
      data = export.show_export_data(hidden_list, hide_times: true)
      expect(data.first).not_to include('Zeit')
      expect(data.flatten).not_to include('15,00')

      judges = export.show_export_data(hidden_list, more_columns: true, hide_times: true)
      expect(judges.map(&:size).uniq.size).to eq 1
      expect(judges.flatten).not_to include('15,00')

      expect(export.show_export_data(hidden_list).flatten).to include('15,00')
    end
  end
end
