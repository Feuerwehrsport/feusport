<%= @user_team_access_request.text %>

---

Dieser Text wurde dir von *<%= @user_team_access_request.sender.name %>* geschickt. Er möchte dich zur Zusammenarbeit beim Wettkampf [<%= @user_team_access_request.competition.name %>](<%= competition_show_url(@user_team_access_request.competition.year, @user_team_access_request.competition.slug) %>) mit der Mannschaft [<%= @team.full_name %>](<%= competition_team_url(@user_team_access_request.competition.year, @user_team_access_request.competition.slug, @team.id) %>) auffordern.

[[Anfrage annehmen]](<%= connect_competition_team_access_request_url(@user_team_access_request.competition.year, @user_team_access_request.competition.slug, @team.id, @user_team_access_request.id) %>)

Sobald du die Anfrage annimmst, hast du vollen Zugriff auf diese Mannschaft und kannst zum Beispiel Wettkämpfer ergänzen.
