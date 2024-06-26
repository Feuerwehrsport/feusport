# frozen_string_literal: true

class Competition < ApplicationRecord
  REGISTRATION_OPEN = { unstated: 0, open: 1, close: 2 }.freeze
  enum registration_open: REGISTRATION_OPEN

  belongs_to :user
  has_many :documents, dependent: :destroy
  has_many :disciplines, dependent: :destroy
  has_many :bands, dependent: :destroy
  has_many :assessments, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :score_results, dependent: :destroy, class_name: 'Score::Result'
  has_many :score_competition_results, dependent: :destroy, class_name: 'Score::CompetitionResult'
  has_many :score_lists, dependent: :destroy, class_name: 'Score::List'
  has_many :score_list_factories, dependent: :destroy, class_name: 'Score::ListFactory'
  has_many :certificates_templates, dependent: :destroy, class_name: 'Certificates::Template'
  has_many :user_access_requests, class_name: 'UserAccessRequest', dependent: :destroy
  has_many :user_accesses, class_name: 'UserAccess', dependent: :destroy
  has_many :users, through: :user_accesses

  scope :visible, -> { where(visible: true) }
  scope :current, -> { visible.where(date: (5.days.ago..5.days.from_now)) }
  scope :upcoming, -> { visible.where(date: (Date.tomorrow..)) }
  scope :previous, -> { visible.where(date: (..Date.yesterday)) }

  before_validation(on: :create) do
    self.year = date&.year
    self.slug = name&.parameterize
    i = 0
    while Competition.exists?(year:, slug:)
      i += 1
      self.slug = "#{name.to_s.parameterize}-#{i}"
    end

    next if date.blank?

    self.description ||= "Der Wettkampf *#{name}* findet am **#{I18n.l date}** in **#{locality}** statt.\n\n" \
                         'Weitere Informationen folgen.'

    self.flyer_headline ||= 'Webseite mit Ergebnissen im Internet'
    self.flyer_content ||= "- Ergebnisse\n- Startlisten"

    self.registration_open_until = date - 1.day
  end
  before_validation(on: :update) do
    next unless date_changed?

    self.registration_open_until = [date - 1.day, registration_open_until].compact_blank.min
  end
  schema_validations
  validates :registration_open_until, presence: true, if: -> { registration_open == 'open' }
  validates :registration_open_until, comparison: { less_than_or_equal_to: :date }, allow_nil: true

  def description_html
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    markdown.render(description)
  end

  def date=(new_date)
    super if new_date.present?
  end

  def year_and_month
    @year_and_month ||= "#{date.year}-#{date.month}"
  end
end
