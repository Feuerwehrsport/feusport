Hallo <%= @user.name %>,

der Nutzer **<%= @actor.name %>** hat dir den Zugang zu dem Wettkampf *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* entfernt.

[[Direkt zum Wettkampf]](<%= competition_show_url(@competition.year, @competition.slug) %>)

Sollte diese Aktion nicht korrekt gewesen sein, wende dich bitte direkt an **<%= @user.name %>**.

