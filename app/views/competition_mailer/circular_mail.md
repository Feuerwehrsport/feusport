Hallo,

der Veranstalter des Wettkampfes *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* schreibt an alle Anmeldungen:

<%= EmailMarkdown.render_user_text(@circular_mail.message) %>

Absender: **<%= @circular_mail.user.name %>** (<%= @circular_mail.user.email %>)

Du erhältst diese E-Mail, weil du eine Mannschaft oder einen Wettkämpfer zu diesem Wettkampf angemeldet hast.

[[Direkt zum Wettkampf]](<%= competition_show_url(@competition.year, @competition.slug) %>)
