# frozen_string_literal: true

class CompetitionMailer < ApplicationMailer
  def access_request
    @access_request = params[:access_request]
    mail(
      to: @access_request.email,
      reply_to: email_address_with_name(@access_request.sender.email, @access_request.sender.name),
      subject: "Zugangsanfrage für Wettkampf - #{@access_request.competition.name}",
    )
  end

  def access_request_connected
    @sender = params[:sender]
    @user = params[:user]
    @competition = params[:competition]

    mail(
      to: email_address_with_name(@sender.email, @sender.name),
      subject: "Zugangsanfrage für Wettkampf verbunden - #{@competition.name}",
    )
  end

  def user_team_access_request
    @user_team_access_request = params[:user_team_access_request]
    @team = @user_team_access_request.team
    mail(
      to: @user_team_access_request.email,
      reply_to: email_address_with_name(@user_team_access_request.sender.email, @user_team_access_request.sender.name),
      subject: "Verwalteranfrage für Mannschaft - #{@user_team_access_request.competition.name} / #{@team.full_name}",
    )
  end

  def user_team_access_request_connected
    @sender = params[:sender]
    @user = params[:user]
    @competition = params[:competition]
    @team = params[:team]

    mail(
      to: email_address_with_name(@sender.email, @sender.name),
      subject: "Verwalteranfrage für Mannschaft verbunden - #{@competition.name} / #{@team.full_name}",
    )
  end

  def registration_team
    @team = params[:team]
    @competition = @team.competition

    mail(
      to: mail_info_users(@competition),
      subject: "Neue Wettkampfanmeldung - #{@team.competition.name}",
    )
  end

  def registration_person
    @person = params[:person]
    @competition = @person.competition

    mail(
      to: mail_info_users(@competition),
      subject: "Neue Wettkampfanmeldung - #{@person.competition.name}",
    )
  end

  def publishing_reminder
    @competition = @params[:competition]

    to = @competition.users.map { |user| email_address_with_name(user.email, user.name) }
    mail(
      to:,
      subject: "Übertrage die Ergebnisse deines Wettkampfs - #{@competition.name}",
    )
  end

  def information_request
    @information_request = @params[:information_request]
    @competition = @information_request.competition

    mail(
      to: mail_info_users(@competition),
      reply_to: email_address_with_name(@information_request.user.email, @information_request.user.name),
      subject: "Informationsanfrage zu deinem Wettkampf - #{@competition.name}",
    )
  end

  def access_deleted
    @competition = @params[:competition]
    @actor = @params[:actor]
    @user = @params[:user]

    to = email_address_with_name(@user.email, @user.name)
    cc = @competition.users.map { |user| email_address_with_name(user.email, user.name) }
    mail(
      to:,
      cc:,
      reply_to: email_address_with_name(@actor.email, @actor.name),
      subject: "Zugang zum Wettkampf entfernt - #{@competition.name}",
    )
  end

  def user_team_access_deleted
    @competition = @params[:competition]
    @actor = @params[:actor]
    @user = @params[:user]
    @team = @params[:team]

    to = email_address_with_name(@user.email, @user.name)
    cc = @team.users.map { |user| email_address_with_name(user.email, user.name) }
    mail(
      to:,
      cc:,
      reply_to: email_address_with_name(@actor.email, @actor.name),
      subject: "Zugang zur Mannschaft entfernt - #{@competition.name} / #{@team.full_name}",
    )
  end

  def mail_info_users(competition)
    competition.user_accesses.where(registration_mail_info: true).map(&:user).map do |user|
      email_address_with_name(user.email, user.name)
    end
  end
end
