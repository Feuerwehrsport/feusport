<%= @access_request.text %>

---

Dieser Text wurde dir von *<%= @access_request.sender.name %>* geschickt. Er möchte dich zur Zusammenarbeit beim Wettkampf [<%= @access_request.competition.name %>](<%= competition_show_url(@access_request.competition.year, @access_request.competition.slug) %>) auffordern.

[[Anfrage annehmen]](<%= connect_competition_access_request_url(@access_request.competition.year, @access_request.competition.slug, @access_request.id, token: @access_request.token) %>)

Die Einladung ist bis zum **<%= l(@access_request.expires_at.to_date) %>** gültig. Danach musst du dich erneut einladen lassen.

Sobald du die Anfrage annimmst, hast du vollen Zugriff auf diesen Wettkampf und kannst zum Beispiel die Beschreibung und Dokumente ergänzen. Wenn du willst, kannst du über feusport.de auch Startlisten erstellen und die komplette Wettkampfauswertung abwickeln.

<% if @access_request.drop_myself? %>
**Wichtig:** Wenn du die Anfrage annimmst, werden *<%= @access_request.sender.name %>* die Rechte für diesen Wettkampf entzogen.
<% end %>
