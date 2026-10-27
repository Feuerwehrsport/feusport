Hallo <%= @user.name %>,

<% if @competitions.one? -%>
es wurde ein neuer Wettkampf auf feusport.de veröffentlicht:
<% else -%>
es wurden neue Wettkämpfe auf feusport.de veröffentlicht:
<% end -%>

<% @competitions.each do |competition| -%>
- [<%= competition.name %>](<%= competition_show_url(competition.year, competition.slug) %>) am *<%= I18n.l(competition.date) %>* in *<%= competition.place %>*
<% end -%>

[[Alle neuen Wettkämpfe ansehen]](<%= root_url(sort: 'published') %>)

Du erhältst diese E-Mail, weil du Benachrichtigungen über neue Wettkämpfe aktiviert hast. In deinem [Benutzerkonto](<%= edit_users_interests_url %>) kannst du das jederzeit ändern oder deinen Filter anpassen.
