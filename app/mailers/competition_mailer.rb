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

  def registration_team
    @team = params[:team]
    @competition = @team.competition

    to = @competition.users.map { |user| email_address_with_name(user.email, user.name) }
    mail(
      to:,
      subject: "Neue Wettkampfanmeldung - #{@team.competition.name}",
    )
  end

  def registration_person
    @person = params[:person]
    @competition = @person.competition

    to = @competition.users.map { |user| email_address_with_name(user.email, user.name) }
    mail(
      to:,
      subject: "Neue Wettkampfanmeldung - #{@person.competition.name}",
    )
  end
end
