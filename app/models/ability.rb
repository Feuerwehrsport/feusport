# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user, simple_access: nil)
    global_abilities

    simple_access_abilities(simple_access) if simple_access.present?
    return if user.nil?

    can(:visit, :disseminator)

    can(:connect, UserAccessRequest)
    can(:connect, UserTeamAccessRequest)

    read_ua = { user_accesses: { user_id: user.id } }
    manage_ua = { user_accesses: { user_id: user.id }, locked_at: nil }

    can(%i[read extend_read], Competition, read_ua)
    can(:manage, Competition, manage_ua)
    can(:unlock, Competition, { user_accesses: { user_id: user.id } })

    can(:read, Document, competition: read_ua)
    can(:manage, Document, competition: manage_ua)

    can(:read, Discipline, competition: read_ua)
    can(:manage, Discipline, competition: manage_ua)
    can(:manage, TeamListRestriction, competition: manage_ua)

    can(:read, Band, competition: read_ua)
    can(:manage, Band, competition: manage_ua)

    can(:read, Assessment, competition: read_ua)
    can(:manage, Assessment, competition: manage_ua)

    can(:read, Team, competition: read_ua)
    can(:manage, Team, competition: manage_ua)

    can(:read, TeamMarker, competition: read_ua)
    can(:manage, TeamMarker, competition: manage_ua)

    can(:manage, TeamMarkerValue, competition: manage_ua)
    can(:manage, TeamMarkerBlockValue, competition: manage_ua)

    can(:read, UserTeamAccess, competition: read_ua)
    can(:manage, UserTeamAccess, competition: manage_ua)
    can(:read, UserTeamAccessRequest, competition: read_ua)
    can(:manage, UserTeamAccessRequest, competition: manage_ua)

    can(:read, Person, competition: read_ua)
    can(:manage, Person, competition: manage_ua)

    can(:read, Certificates::Template, competition: read_ua)
    can(:manage, Certificates::Template, competition: manage_ua)
    can(:manage, Certificates::List, competition: manage_ua)
    can(:manage, Certificates::Import, competition: manage_ua)

    can(:read, Score::List, competition: read_ua)
    can(:manage, Score::List, competition: manage_ua)

    can(:manage, Score::ListEntry, competition: manage_ua)
    can(:manage, Score::Run, competition: manage_ua)

    can(:read, Score::Result, competition: read_ua)
    can(:manage, Score::Result, competition: manage_ua)

    can(:read, Score::CompetitionResult, competition: read_ua)
    can(:manage, Score::CompetitionResult, competition: manage_ua)

    can(:manage, Score::ListFactory, competition: manage_ua)
    can(:manage, Score::ListPrintGenerator, competition: manage_ua)
    can(:manage, Score::ListCondition, competition: manage_ua)

    can(:manage, SimpleAccess, competition: manage_ua)

    can(:read, UserAccess, competition: read_ua)
    can(:manage, UserAccess, competition: manage_ua)

    can(:read, UserAccessRequest, competition: read_ua)
    can(:manage, UserAccessRequest, competition: manage_ua)

    can(:create, InformationRequest, &:possible?)

    can(:read, FireSportStatistics::Publishing, competition: read_ua)
    can(:manage, Competitions::Publishing, competition: manage_ua)
    can(:manage, Presets::Base) { |preset| can?(:manage, preset.competition) }
    can(:manage, Competitions::Duplication) { |duplication| can?(:manage, duplication.competition) }

    can(%i[create], Team) { |team| team.competition.registration_possible? }
    can(%i[edit sub_edit assessment_requests update destroy], Team) do |team|
      team.users.include?(user) && team.competition.registration_possible?
    end
    can(%i[sub_edit], Team) do |team|
      team.users.include?(user) && team.competition.change_people_possible?
    end

    can(:manage, UserTeamAccess) { |access| can?(:update, access.team) }
    can(%i[create destroy], UserTeamAccessRequest) do |access|
      access.team.blank? || can?(:update, access.team)
    end

    can(%i[create], Person) do |person|
      (
        (person.team.nil? || person.team.users.include?(user)) &&
        person.competition.registration_possible?
      ) || (
        person.team.present? && person.team.users.include?(user) &&
        person.competition.change_people_possible?
      )
    end
    can(%i[edit_assessment_requests update destroy], Person) do |person|
      (person.users.include?(user) || person.team&.users&.include?(user)) &&
        (person.competition.registration_possible? || person.competition.change_people_possible?)
    end
  end

  def global_abilities
    can(:read, Competition, visible: true)
    can(%i[read download preview image], Document, competition: { visible: true })
    can(:read, Discipline, competition: { visible: true })
    can(:read, Band, competition: { visible: true })
    can(:read, Assessment, competition: { visible: true })
    can(:read, Team, competition: { visible: true })
    can(:read, Person, competition: { visible: true })
    can(:read, Score::List, competition: { visible: true })
    can(:read, Score::Result, competition: { visible: true })
    can(:read, Score::CompetitionResult, competition: { visible: true })
  end

  def simple_access_abilities(simple_access)
    return if simple_access.competition.locked?

    can(:manage, Competition, id: simple_access.competition_id)
    can(:manage, Document, competition: { id: simple_access.competition_id })
    can(:manage, Discipline, competition: { id: simple_access.competition_id })
    can(:manage, TeamListRestriction, competition: { id: simple_access.competition_id })
    can(:manage, Band, competition: { id: simple_access.competition_id })
    can(:manage, Assessment, competition: { id: simple_access.competition_id })
    can(:manage, Team, competition: { id: simple_access.competition_id })
    can(:manage, TeamMarker, competition: { id: simple_access.competition_id })
    can(:manage, TeamMarkerValue, competition: { id: simple_access.competition_id })
    can(:manage, TeamMarkerBlockValue, competition: { id: simple_access.competition_id })
    can(:manage, Person, competition: { id: simple_access.competition_id })
    can(:manage, Certificates::Template, competition: { id: simple_access.competition_id })
    can(:manage, Certificates::List, competition: { id: simple_access.competition_id })
    can(:manage, Certificates::Import, competition: { id: simple_access.competition_id })
    can(:manage, Score::List, competition: { id: simple_access.competition_id })
    can(:manage, Score::ListEntry, competition: { id: simple_access.competition_id })
    can(:manage, Score::Run, competition: { id: simple_access.competition_id })
    can(:manage, Score::Result, competition: { id: simple_access.competition_id })
    can(:manage, Score::CompetitionResult, competition: { id: simple_access.competition_id })
    can(:manage, Score::ListFactory, competition: { id: simple_access.competition_id })
    can(:manage, Score::ListPrintGenerator, competition: { id: simple_access.competition_id })
    can(:manage, Score::ListCondition, competition: { id: simple_access.competition_id })
  end
end
