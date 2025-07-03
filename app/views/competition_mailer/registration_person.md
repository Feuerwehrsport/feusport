Hallo,

zu deinem Wettkampf *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* wurde ein neuer Einzelstarter angemeldet:

Name: **<%= @person.full_name %>**
Wertungsgruppe: **<%= @person.band.name %>**
Angemeldet durch: **<%= @person.users.map(&:name).join(', ') %>**

Anmeldungshinweise:
<%= @person.registration_hint %>

[[Direkt zum Wettkämpfer]](<%= competition_person_url(@competition.year, @competition.slug, @person.id) %>)

**Wichtig:** Du wirst über weitere Änderungen bezüglich dieses Wettkämpfers nicht nochmal informiert. Der Nutzer kann noch bis einschließlich <%= l(@competition.registration_open_until) %> Änderungen vornehmen.
