Hallo,

zu deinem Wettkampf *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* wurde eine Informationsanfrage gestellt:

Name: **<%= @information_request.user.name %>**
Abkürzung: **<%= @information_request.user.email %>**

Nachricht:

<%= @information_request.message %>

[[Direkt zum Wettkampf]](<%= competition_show_url(@competition.year, @competition.slug) %>)
