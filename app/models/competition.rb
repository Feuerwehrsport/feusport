# frozen_string_literal: true

# == Schema Information
#
# Table name: competitions
#
#  id                      :uuid             not null, primary key
#  date                    :date             not null
#  description             :text
#  flyer_content           :text
#  flyer_headline          :string
#  locked_at               :datetime
#  lottery_numbers         :boolean          default(FALSE), not null
#  name                    :string(50)       not null
#  place                   :string(50)       not null
#  preset_ran              :boolean          default(FALSE), not null
#  registration_open       :integer          default("unstated"), not null
#  registration_open_until :date
#  show_bib_numbers        :boolean          default(FALSE), not null
#  slug                    :string(50)       not null
#  visible                 :boolean          default(FALSE), not null
#  year                    :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  wko_id                  :uuid
#
# Indexes
#
#  index_competitions_on_date           (date)
#  index_competitions_on_wko_id         (wko_id)
#  index_competitions_on_year_and_slug  (year,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (wko_id => wkos.id)
#
class Competition < ApplicationRecord
  REGISTRATION_OPEN = { unstated: 0, open: 1, close: 2 }.freeze
  enum :registration_open, REGISTRATION_OPEN, scopes: false, prefix: true

  belongs_to :wko
  has_many :documents, dependent: :destroy
  has_many :disciplines, dependent: :destroy
  has_many :bands, dependent: :destroy
  has_many :assessments, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :team_relays, through: :teams
  has_many :team_markers, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :score_results, dependent: :destroy, class_name: 'Score::Result'
  has_many :score_competition_results, dependent: :destroy, class_name: 'Score::CompetitionResult'
  has_many :score_lists, dependent: :destroy, class_name: 'Score::List'
  has_many :score_list_factories, dependent: :destroy, class_name: 'Score::ListFactory'
  has_many :certificates_templates, dependent: :destroy, class_name: 'Certificates::Template'
  has_many :user_access_requests, class_name: 'UserAccessRequest', dependent: :destroy
  has_many :user_accesses, class_name: 'UserAccess', dependent: :destroy
  has_many :users, through: :user_accesses
  has_many :score_list_print_generators, class_name: 'Score::ListPrintGenerator', dependent: :destroy
  has_many :simple_accesses, class_name: 'SimpleAccess', dependent: :destroy
  has_many :team_list_restrictions, dependent: :destroy
  has_many :information_requests, dependent: :destroy

  scope :current, -> { where(date: (14.days.ago..6.months.from_now)) }

  before_validation(on: :create) do
    self.year = date&.year
    self.slug = name&.parameterize
    i = 0
    while Competition.exists?(year:, slug:)
      i += 1
      self.slug = "#{name.to_s.parameterize}-#{i}"
    end

    self.flyer_headline ||= 'Webseite mit Ergebnissen im Internet'
    self.flyer_content ||= "- Ergebnisse\n- Startlisten"

    next if date.blank?

    self.description ||= "Der Wettkampf *#{name.strip}* findet am **#{I18n.l date}** in **#{place.strip}** statt.\n\n" \
                         'Weitere Informationen folgen.'
    self.registration_open_until = date - 1.day
  end
  before_validation(on: :update) do
    next unless date_changed?

    self.registration_open_until = [date - 1.day, registration_open_until].compact_blank.min
  end

  auto_strip_attributes :name, :place, :slug, :description, :flyer_headline, :flyer_content
  before_validation { self.slug = slug.to_s.parameterize }
  schema_validations
  validates :registration_open_until, presence: true, if: -> { registration_open == 'open' }
  validates :registration_open_until, comparison: { less_than_or_equal_to: :date }, allow_nil: true

  after_touch do
    FireSportStatistics::Person.dummies.delete_all
    FireSportStatistics::Team.dummies.delete_all
  end

  def description_html
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    markdown.render(description)
  end

  def date=(new_date)
    super if new_date.present?
  end

  def self_url
    Rails.application.routes.url_helpers.competition_show_url(Rails.application.config.default_url_options.merge(
                                                                year: year,
                                                                slug: slug,
                                                              ))
  end

  def year_and_month
    @year_and_month ||= "#{date.year}-#{date.month}"
  end

  def registration_possible?
    return false if locked?
    return false unless registration_open_open?
    return false unless visible?
    return false if registration_open_until.nil?

    registration_open_until.end_of_day > Time.current
  end

  def locked?
    !locked_at.nil?
  end

  def full_name
    "#{date} #{name}"
  end
end
