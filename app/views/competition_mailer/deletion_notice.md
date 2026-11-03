Hallo,

dein Wettkampf *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* ist nicht öffentlich sichtbar. Nicht öffentliche Wettkämpfe werden ein Jahr nach dem Wettkampfdatum automatisch gelöscht. Dein Wettkampf wird deshalb am *<%= I18n.l(Competitions::AutoDeletion.deletion_date(@competition)) %>* gelöscht.

Wenn du ihn behalten möchtest, mach ihn bis dahin öffentlich sichtbar. Brauchst du ihn nicht mehr, musst du nichts weiter tun.

[[Zum Wettkampf]](<%= competition_show_url(@competition.year, @competition.slug) %>)
