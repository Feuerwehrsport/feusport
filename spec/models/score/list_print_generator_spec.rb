# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_print_generators
#
#  id             :uuid             not null, primary key
#  print_list     :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_score_list_print_generators_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Score::ListPrintGenerator do
  describe 'validation' do
    let(:competition) { create(:competition) }

    it 'checks print_list' do
      instance = described_class.new(print_list: 'a', competition:)
      expect(instance).not_to be_valid
      expect(instance.errors.attribute_names).to include :print_list

      instance.print_list = "page\ncolumn"
      expect(instance).to be_valid

      instance.print_list = "page\ncolumn\n#{SecureRandom.uuid}"
      expect(instance).to be_valid

      instance.print_list = "page\ncolumn\n#{SecureRandom.uuid}\nfoo"
      expect(instance).not_to be_valid
      expect(instance.errors.attribute_names).to include :print_list

      expect(instance.print_list_extended).to eq %w[page column]
    end
  end
end
