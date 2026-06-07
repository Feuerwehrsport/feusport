Hallo,

dein Wettkampf *<%= @competition.name %>* am *<%= I18n.l(@competition.date) %>* war hoffentlich ein voller Erfolg. Falls du schöne Bilder geschossen hast, lade doch ein paar Schnappschüsse hoch. Einen davon kannst du als Highlight markieren und somit prominent auf deinen Wettkampf verlinken lassen.

[[Schnappschuss hochladen]](<%= new_competition_snapshot_url(@competition.year, @competition.slug) %>)

Trage doch auch gleich den Termin für das nächste Jahr bei Feusport ein. Dann können sich alle gleich das Datum vormerken.
