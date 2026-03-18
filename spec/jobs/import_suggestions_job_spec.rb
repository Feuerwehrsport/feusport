# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportSuggestionsJob do
  describe 'import job' do
    it 'imports entities from feuerwehrsport-statistik.de', :vcr do
      described_class.perform_now

      expect(FireSportStatistics::Person.count).to eq 4
      expect(FireSportStatistics::PersonSpelling.count).to eq 1
      expect(FireSportStatistics::Team.count).to eq 5
      expect(FireSportStatistics::TeamSpelling.count).to eq 16
      expect(FireSportStatistics::TeamAssociation.count).to eq 5

      expect(FireSportStatistics::Person.find(271).attributes.except('updated_at', 'created_at')).to eq(
        'dummy' => false,
        'first_name' => 'Georg',
        'gender' => 'male',
        'id' => 271,
        'last_name' => 'Limbach',
        'personal_best_hb' => 1796,
        'personal_best_hb_competition' => '28.05.2016 - Doberlug-Kirchhain, D-Cup',
        'personal_best_hl' => 1634,
        'personal_best_hl_competition' => '07.06.2014 - Charlottenthal, MV-Cup (20. Pfingstpokal)',
        'personal_best_zk' => 3497,
        'personal_best_zk_competition' => '24.08.2019 - Ludwigslust, Landesausscheid ' \
                                          '(Landesmeisterschaften Mecklenburg-Vorpommern)',
        'saison_best_hb' => nil,
        'saison_best_hb_competition' => nil,
        'saison_best_hl' => 1992,
        'saison_best_hl_competition' => '24.01.2026 - Tribsees, Neujahrssteigen (Neujahrssteigen 2026)',
        'saison_best_zk' => nil,
        'saison_best_zk_competition' => nil,
      )

      expect(Series::TeamParticipation.count).to eq 22
      expect(Series::PersonParticipation.count).to eq 30
      expect(Series::TeamAssessment.count).to eq 5
      expect(Series::PersonAssessment.count).to eq 4
      expect(Series::Cup.count).to eq 7
      expect(Series::Round.count).to eq 3
    end
  end
end
