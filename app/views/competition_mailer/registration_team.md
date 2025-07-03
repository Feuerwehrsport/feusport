Hallo,

zu deinem Wettkampf *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* wurde eine neue Mannschaft angemeldet:

Name: **<%= @team.full_name %>**
Abkürzung: **<%= @team.shortcut %>**
Wertungsgruppe: **<%= @team.band.name %>**
Angemeldet durch: **<%= @team.users.map(&:name).join(', ') %>**

Anmeldungshinweise:
<%= @team.registration_hint %>

[[Direkt zur Mannschaft]](<%= competition_team_url(@competition.year, @competition.slug, @team.id) %>)

**Wichtig:** Du wirst über weitere Änderungen bezüglich dieser Mannschaft nicht nochmal informiert. Der Nutzer kann noch bis einschließlich <%= l(@competition.registration_open_until) %> Änderungen vornehmen.
