# frozen_string_literal: true

class Presets::SingleDisciplines < Presets::Base
  attr_reader :selected_bands, :selected_disciplines

  validates :selected_bands, :selected_disciplines, presence: true

  def name
    'Eine oder mehrere Einzeldisziplinen (HL, HB, ZK)'
  end

  def params
    [
      Param.new(:selected_bands, as: :check_boxes, collection: [
                  %w[Frauen female], %w[Männer male],
                  ['Jugend (ungeschlechtlich)', 'youth'],
                  ['Mädchen', 'girls'],
                  ['Jungen', 'boys'],
                  ['Frauen - U15', 'girls-u15'],
                  ['Männer - U15', 'boys-u15']
                ]),
      Param.new(:selected_disciplines, as: :check_boxes, collection: [
                  %w[Hakenleitersteigen hl], %w[100m-Hindernisbahn hb], %w[Zweikampf zk]
                ]),
    ]
  end

  def selected_bands=(array)
    @selected_bands = array.compact_blank
  end

  def selected_disciplines=(array)
    @selected_disciplines = array.compact_blank
  end

  protected

  def perform
    bands = []
    {
      'female' => [:female, 'Frauen'],
      'male' => [:male, 'Männer'],
      'youth' => [:indifferent, 'Jugend'],
      'girls' => [:female, 'Mädchen'],
      'boys' => [:male, 'Jungen'],
      'girs-u15' => [:female, 'Frauen - U15'],
      'bos-u15' => [:male, 'Männer - U15'],
    }.each do |band_name, opts|
      gender, name = opts
      bands.push(competition.bands.find_or_create_by!(gender:, name:)) if band_name.in?(selected_bands)
    end

    zk_result = {}
    if 'zk'.in?(selected_disciplines)
      bands.each do |band|
        zk_result[band] =
          Score::Result.create!(competition:, multi_result_method: :sum_of_best,
                                forced_name: "Zweikampf - #{band.name}", image_key: :zk)
      end
    end

    if 'hl'.in?(selected_disciplines)
      hl = competition.disciplines.find_or_create_by(key: :hl, name: Discipline::DEFAULT_NAMES[:hl], short_name: 'HL',
                                                     single_discipline: true)
      bands.each do |band|
        hl_assessment = competition.assessments.find_or_create_by!(discipline: hl, band:)
        result = competition.score_results.find_or_create_by!(assessment: hl_assessment)
        zk_result[band].results.push(result) if zk_result[band]
      end
    end
    if 'hb'.in?(selected_disciplines)
      hb = competition.disciplines.find_or_create_by(key: :hb, name: Discipline::DEFAULT_NAMES[:hb], short_name: 'HB',
                                                     single_discipline: true)
      bands.each do |band|
        hb_assessment = competition.assessments.find_or_create_by!(discipline: hb, band:)
        result = competition.score_results.find_or_create_by!(assessment: hb_assessment)
        zk_result[band].results.push(result) if zk_result[band]
      end
    end

    true
  end
end
