# Todo

Stand: 17. Oktober 2026, Rails 8.1.4 (`load_defaults 8.1`), 523 Tests grün, Line Coverage 100 % (5536/5536), Rubocop und haml-lint sauber.
Letzte Commits: „Maximale Anzahl von Mannschaften erlauben“, „Mehr Validierungen auf gleichen Wettkampf“.

## Arbeitsweise in diesem Projekt (für Claude)

### Zusammenarbeit
- Kommunikation, UI-Texte und Commit-Messages auf Deutsch. Commit-Messages kurz, im Stil der bestehenden (`git log`).
- Georg committet meist selbst. Nur committen, wenn ausdrücklich gewünscht.
- Bei fachlich mehrdeutigen Anforderungen vor der Umsetzung kurz nachfragen (z. B. „zählt das Limit Mannschaften oder Personen?“).
- Wenn Georg sagt „beheben, aber Hinweise nicht“, dann wirklich nur die genannten Punkte anfassen.

### Pflicht nach jeder Änderung
- Abdeckung muss bei 100 % bleiben, Rubocop und haml-lint müssen sauber sein:
  ```sh
  bundle exec rubocop && bundle exec haml-lint app/views && bundle exec rspec
  ```
  `bundle exec rspec` gibt am Ende `Line coverage: x / y` aus.
- Schnell und ohne SimpleCov: `CI_SERVER=1 bundle exec rspec <dateien>`. **Achtung:** Ein Lauf mit SimpleCov überschreibt das eingecheckte `doc/simplecov.json`. Bei Teil-Läufen und Wegwerf-Tests deshalb immer `CI_SERVER=1` setzen. Ein voller Lauf aktualisiert die Datei bewusst. Subagenten das ausdrücklich mitgeben.
- Ungedeckte Zeilen pro Datei:
  ```sh
  ruby -rjson -e 'rs = JSON.parse(File.read("coverage/.resultset.json")).values.first["coverage"]
  rs.each { |f, d| m = d["lines"].each_with_index.select { |v, _| v == 0 }.map { |_, i| i + 1 }
  puts "#{f.sub(Dir.pwd + "/", "")}: #{m.join(",")}" if m.any? }'
  ```
  `.resultset.json` meldet auch Zeilen zwischen `# simplecov:disable` / `# simplecov:enable` als `0`. Vorher in der Datei prüfen. Dateien, die kein Test lädt, fehlen im Resultset, zählen aber (`.simplecov` setzt `cover '{app,lib}/**/*.rb'`).

### Datenbank und Migrationen
- `bin/rails db:migrate` läuft annotate automatisch: Es aktualisiert die Schema-Kommentare in Models und Specs und **generiert `app/models/concerns/schema_validations.rb` neu** (Validierungen aus dem DB-Schema). Diese Diffs sind gewollt.
- Danach die Testdatenbank laden: `RAILS_ENV=test bin/rails db:schema:load`.
- Migrationen erben von `ActiveRecord::Migration[8.1]` (bestehende behalten ihre Version).
- Parallele Testläufe: `DATABASE_URL="postgis://feusport:feusport@localhost/feusport-test-N" RAILS_ENV=test bin/rails db:create db:schema:load`, eigenes Coverage-Verzeichnis per `-r`-Datei mit `SimpleCov.coverage_dir(ENV.fetch('COV_DIR'))`.

### Specs
- Request-, Controller-, Feature- und Mailer-Specs laufen mit eingefrorener Zeit (`spec_views` setzt per Timecop `2024-02-29 00:17:42`). Model-Specs nicht. `competition.update!(registration_open_until: Date.current, …)` funktioniert deshalb nur in Request-Specs, weil der Factory-Wettkampf am 2024-02-29 stattfindet.
- Wegwerf-Specs zum Nachweisen einer Lücke unter `spec/requests/tmp_probe/` ablegen (wegen der eingefrorenen Zeit), mit `CI_SERVER=1` laufen lassen und danach wieder löschen.
- Nicht auf `created_at` sortieren (alle Datensätze haben im Request-Spec denselben Zeitstempel). Eindeutigen Schlüssel ergänzen (z. B. `:slug`) oder eindeutige Namen vergeben.
- HTML-Snapshots (`match_html_fixture`) liegen in `spec/fixtures/views/<Name>/view.html`. Bei Abweichung schreibt spec_views `challenger.html` daneben, und der Test bricht beim **ersten** Unterschied ab. Übernehmen: Diff ansehen, `challenger.html` nach `view.html` verschieben, Spec erneut laufen lassen, bis er grün ist. Veraltete `challenger.html` löschen (sie sind gitignored).
- Für neue Prüfungen reichen oft `expect(response.body).to include(...)` statt neuer Snapshots.
- Views so ändern, dass bestehende Snapshots ohne Feature-Daten gleich bleiben. Z. B. Inline-Interpolation statt neuer HAML-Zeilen, sonst ändert sich Whitespace in vielen Fixtures.
- Factories: Bei `create(:person)`, `create(:team)` usw. immer `competition:` (und passende `band:`) mitgeben, sonst entsteht ein zweiter Wettkampf. Seit den `same_competition`-Validierungen schlägt das fehl.
- `RSpec/AnyInstance` ist deaktiviert, `allow_any_instance_of` ist erlaubt.
- Hilfsmethoden: `competition_nested('teams/…')` für Pfade, `expect_access_denied` (nur für nicht angemeldete Benutzer; angemeldet gibt es Redirect auf `/` mit Flash `Zugriff verweigert`).

### Konventionen im Code
- Texte gehören in `config/locales/*.de.yml`, nicht als Konstanten in Controller. Danach `bundle exec i18n-tasks normalize` ausführen (`spec/i18n_spec.rb` prüft fehlende Schlüssel und Normalisierung).
- Flash-Meldungen als Symbol (`notice: :saved`, `alert: :band_full`). Das Layout übersetzt sie über `alerts.*` in `config/locales/de.yml`.
- Fehlermeldungen für `errors.add(:attr, :key)` stehen unter `activerecord.errors.messages`.
- Berechtigungen: CanCanCan in `app/models/ability.rb`. `CompetitionNestedController.default_resource` ruft `load_and_authorize_resource … through: :competition` auf. **Die Berechtigung wird geprüft, bevor `assign_attributes(params)` läuft.** Jede erlaubte ID in den Strong Params (`xxx_id`, `xxx_ids`, nested attributes) kann deshalb auf fremde Datensätze zeigen. Darum `validates :x, same_competition: true` (`app/validators/same_competition_validator.rb`) setzen und nach dem Zuweisen bei Bedarf erneut `authorize!` aufrufen (Beispiel: `authorize_person_team!` im PeopleController).
- „Admin“ heißt im Code `can?(:manage, @competition)`. Das gilt auch für Gast-Logins (SimpleAccess).
- Mannschaftsleiter = Benutzer mit `UserTeamAccess`. Einzelanmelder = Benutzer mit `UserPersonAccess`.
- Wertungsgruppe = `Band`, Wertung = `Assessment`, Startliste = `Score::List`, Ergebnis = `Score::Result`.
- Content Security Policy (`config/initializers/content_security_policy.rb`): keine Inline-Skripte und keine `onclick`/`on…`-Attribute, JS gehört nach `app/javascript`. Neue externe Quellen (Skripte, Verbindungen, Frames) müssen dort freigegeben werden. Die Specs merken CSP-Verstöße nicht, im Browser prüfen.

### Werkzeuge
- Breite Prüfungen (z. B. ein Sicherheits-Audit) auf mehrere parallele Agenten mit getrennten Bereichen aufteilen und sie ausdrücklich nur lesend arbeiten lassen. Ergebnisse vor der Weitergabe selbst gegen den Code prüfen.

## Offene Punkte: Sicherheit (Audit vom 6. Oktober 2026)

Status: gefunden, offen, sofern nicht abgehakt. Reihenfolge nach Schwere. Zeilenangaben können sich verschieben, darum sind Methoden genannt.
Die Nummern (S1, S2, … und H1, H2, …) sind feste Referenzen: Erledigte Punkte abhaken (`[x]`) und in den Abschnitt „Erledigt“ am Ende der Datei verschieben, nie neu nummerieren. Neue Funde bekommen die nächste freie Nummer.
Für jede Lücke beim Beheben einen Regressions-Spec schreiben und prüfen, dass er ohne Fix fehlschlägt (z. B. `git stash push -- app`, Spec laufen lassen, `git stash pop`).

### Hoch

Keine offenen Punkte.

### Mittel

Keine offenen Punkte.

### Niedrig

Keine offenen Punkte.

## Offene Punkte: Wartung

Nummern wie bei der Sicherheit fest vergeben (W1, W2, …), erledigte abhaken und nach „Erledigt“ verschieben.

- [ ] **W1 `spec_views` (eigenes Gem) aktualisieren**
  - Hält `diff-lcs` auf `~> 1.5` fest (aktuell 1.6.2, neueste 2.0.0). Auch `rspec-expectations` und `rspec-mocks` verlangen noch `< 2.0`, ein Update von `spec_views` allein reicht also nicht.
  - Bei der Gelegenheit prüfen: Bei einer Abweichung bricht `match_html_fixture` beim ersten Unterschied ab. Beim Rails-8.1-Update waren deshalb viele Durchläufe nötig, bis alle Snapshots übernommen waren. Alle Unterschiede auf einmal zu melden oder zu schreiben würde das abkürzen.
- [ ] **W3 Sass-Deprecations vor Dart Sass 3.0**
  - Eigener Code ist umgestellt (29. Oktober 2026): `@use` statt `@import`, `sass:color`/`sass:math`/`sass:string` statt globaler Funktionen, kein altes `if()` mehr. Bootstrap wird in `app/assets/stylesheets/bootstrap/_bootstrap.scss` per `@forward 'bootstrap/scss/bootstrap' with (…)` konfiguriert. Dort stehen nur noch die vom Standard abweichenden Variablen statt einer Kopie von `_variables.scss`. Eigene Stylesheets binden Bootstrap mit `@use 'bootstrap/bootstrap' as *` ein. Font Awesome Pro 6.2.1 (Kopie in `fontawesome/`) ist ebenfalls auf Module umgestellt.
  - Kompiliertes CSS war danach identisch, bis auf den Bootstrap-Banner und die Reihenfolge in zwei Selektorlisten. Achtung: Bootstraps `@extend` (z. B. `.h1` → `h1`, `.small` → `small`) greift nicht mehr in eigene Regeln durch, solche Selektoren deshalb selbst ergänzen (siehe `.card-header`, `.page-header`, `.form-group.boolean`).
  - Offen: Bootstrap 5.3 (auch 5.3.8) nutzt intern weiter `@import` und globale Funktionen. `build:css` blendet diese Warnungen mit `--quiet-deps` aus. Mit Dart Sass 3.0 bricht das trotzdem. Erst Bootstrap 6 ist auf Module umgestellt (Stand heute nur `6.0.0-alpha.1`). Sobald Bootstrap 6 stabil ist: umstellen und `--quiet-deps` prüfen. Bis dahin `sass` nicht auf 3.x heben.
- [ ] **W4 Node 18 ist veraltet**
  - Lokal läuft Node 18.19 (seit April 2025 ohne Support). `sass` ab 1.100 verlangt Node ≥ 20.19, deshalb ist `sass` auf `~1.99.0` festgelegt. Vorher klären, welche Node-Version auf dem Build-/Deploy-Server läuft, dann Node anheben und `sass` wieder auf `^` stellen.

## Erledigt

Abgehakte Punkte aus den Abschnitten oben, nach Nummer sortiert. Die ursprüngliche Schwere steht in Klammern hinter der Nummer.

- [x] **S1 Fremde Mannschaft übernehmen** (Hoch) (bestätigt per Spec) – **behoben**
  - `app/views/competitions/user_team_accesses/index.html.haml` zeigt offene Einladungen (`@competition.user_team_access_requests.where(team: @team)`) mit `req.id` und E-Mail ohne Berechtigungsprüfung. `UserTeamAccessesController#preauthorize` prüft nur `authorize!(:index, UserTeamAccess)` auf die Klasse, und das ist für jeden angemeldeten Benutzer erfüllt.
  - `UserTeamAccessRequestsController#connect` verlangt nur `:connect` (`ability.rb`: `can(:connect, UserTeamAccessRequest)` für alle).
  - Angriff: Team-ID aus der öffentlichen Seite holen, `GET /:year/:slug/teams/<team>/accesses`, dann `GET …/access_requests/<req>/connect`. Danach ist der Angreifer Mannschaftsleiter.
  - Fix-Idee: Einladungsliste nur zeigen, wenn `can?(:update, @team)`. `index` nur erlauben, wenn der Benutzer das Team bearbeiten darf. Besser zusätzlich ein eigenes geheimes Token statt der Datensatz-ID im Link, oder die E-Mail des Benutzers muss zur Einladung passen. Dasselbe für `UserAccessRequest` (Wettkampf-Admins) prüfen; dort ist der Index geschützt.
  - Umsetzung: Neue Spalte `user_team_access_requests.token` (`has_secure_token on: :initialize`, Altdaten per Migration befüllt). Der Link in der Mail lautet `…/connect?token=…`, `connect` prüft per `valid_token?` (`secure_compare`), sonst „Der Link ist ungültig.“. Der Token taucht nie im Index auf. `UserTeamAccessesController#preauthorize` prüft jetzt auf eine Instanz mit `@team` (→ `can?(:update, team)`), Außenstehende bekommen „Zugriff verweigert“.
  - Wettkampf-Einladungen (`UserAccessRequest`) haben genauso einen Token bekommen (`connect` leitet bei falschem Token zur Wettkampfseite).
  - Folge für den Betrieb: Vor dem Deploy verschickte Einladungs-Mails enthalten keinen Token mehr, und ihre Links funktionieren nicht. Betroffene müssen neu eingeladen werden.
- [x] **S2 Offene Weiterleitung** (Hoch) (bestätigt per Spec) – **behoben**
  - `ApplicationController#ensure_correct_host!`: `redirect_to url_for(params.permit!.to_h.merge(host:, port:, protocol:)), allow_other_host: true`. `?domain=evil.com` oder `?script_name=@evil.com` führen auf eine fremde Domain. Das greift, sobald Host, Port oder Protokoll vom Sollwert abweichen (http, www, IP).
  - Fix-Idee: URL aus `"#{correct_protocol}://#{correct_host}#{port_suffix}#{request.fullpath}"` bauen, keine Params an `url_for`.
  - Umsetzung: Die Ziel-URL wird mit `ActionDispatch::Http::URL.full_url_for(host:, port:, protocol:, path: request.fullpath)` gebaut. Params landen nur noch unverändert im Query-String, Standard-Ports (80/443) entfallen wie bisher. Regressions-Specs in `spec/requests/application_controller_spec.rb` (Params `domain`, `script_name`, `host`, `subdomain` sowie falscher Port).
- [x] **S3 `*_ids=` schreibt Verknüpfungen zu fremden Wettkämpfen sofort** (Hoch) (bestätigt per Runner) – **behoben**
  - Bei gespeicherten Datensätzen schreibt Rails `has_many :through`-IDs sofort beim Zuweisen. `same_competition` schlägt erst beim `save` fehl, die Join-Zeilen sind dann schon da.
  - Betroffen: `score/lists_controller.rb` (`assessment_ids`, `result_ids`), `score/competition_results_controller.rb` (`result_ids`), `score/results_controller.rb` (`result_ids` für Mehrfach-Ergebnisse), `score/list_factories_controller.rb` (`assessment_ids`, `result_ids`), `score/list_conditions_controller.rb` (`assessment_ids`).
  - Folge: Admin von A hängt Wertungen oder Ergebnisse von B an. B kann diese Datensätze danach nicht mehr speichern oder löschen, und A zeigt Daten von B an.
  - Fix-Idee: IDs im Controller auf `@competition.<assoc>.where(id: …).pluck(:id)` einschränken, oder Setter im Model überschreiben.
  - Umsetzung: Neuer Concern `CompetitionScopedIds` (`app/models/concerns/competition_scoped_ids.rb`). `competition_scoped_ids :assessments, results: :score_results` überschreibt `*_ids=` und lässt nur IDs aus dem eigenen Wettkampf durch, fremde werden still verworfen. Eingebunden in `Score::List`, `Score::ListFactory`, `Score::ListCondition` (`assessments`), `Score::CompetitionResult` und `Score::Result` (`results`). Die `same_competition`-Validierungen bleiben als zweite Absicherung, z. B. für `assessments = […]`. Regressions-Specs: `spec/requests/competitions/score/foreign_ids_spec.rb`.
- [x] **S4 Versteckte Ergebnisse in Exporten** (Mittel) – **behoben**
  - `score/competition_results_controller.rb#index`: PDF/XLSX enthalten Gesamtwertungen mit `hidden: true` (nur `index.html.haml` filtert). Anonym abrufbar.
  - `score/lists_controller.rb#show`: PDF/XLSX zeigen Zeiten trotz `hidden_results` und versteckte Listen (`hidden`), nur die HTML-Ansicht prüft das.
  - Fix-Idee: Für Nicht-Admins (`!can?(:manage, @competition)`) versteckte Einträge vor dem Export filtern bzw. Zeiten ausblenden.
  - Vorgaben von Georg: Startlisten mit `hidden` **oder** `hidden_results` zählen öffentlich nicht in Ergebnisse. Admins (`can?(:manage, @competition)`, inkl. Gastzugang) sehen alles mit Hinweis und markierter Spalte. Serien nur öffentlich. Übertragung nur öffentliche Listen, mit Hinweis auf der Übertragungsseite. Urkunden (nur Admins/Gastzugang) immer mit allen Listen.
  - Umsetzung: `Score::List#results_public?`. `Score::Result#include_hidden_lists` (ersetzt `show_hidden_result`), `#shown_lists` (Spalten und Berechnung), `#hidden_lists`; der Schalter wird an Teilergebnisse (Mehrfachwertung) und von `Score::CompetitionResult` weitergegeben. `CompetitionNestedController#include_hidden_lists?` setzt ihn in `ResultsController` und `CompetitionResultsController`.
  - Verhaltensänderungen: `hidden`-Listen flossen bisher nie ein, jetzt für Admins schon. `ListFactories::Best` nutzt jetzt auch nicht öffentliche Vorläufe (vorher ignoriert, auch `hidden_results`).
  - Exporte: Ergebnis-PDF/XLSX/JSON nur `shown_lists`, für Admins Spaltenkopf „(versteckt)“. Gesamtwertungen: versteckte (`hidden`) nur für Admins exportiert, `show` leitet Besucher um. Startlisten-Export für Besucher: versteckte Liste → Umleitung, versteckte Ergebnisse → ohne Zeiten/Ziele (`hide_times`, auch in der Kampfrichter-Fassung).
  - Hinweise (Partial `score/results/_hidden_lists_notice`): Ergebnisseite, Gesamtwertungen, Übertragung, Urkunden. Übersichtskarte zeigt Besuchern nur öffentliche Listen.
  - Specs: `spec/models/score/hidden_lists_spec.rb`, `spec/requests/competitions/score/hidden_lists_spec.rb`.
  - Live-Kanal für Admins mit S5 nachgezogen (eigener Admin-Stream).
- [x] **S5 ActionCable ohne Berechtigung** (Mittel) – **behoben**
  - `app/channels/application_cable/connection.rb` ist leer. `ScoreListChannel#subscribed` streamt `score_list_#{id}_editable_#{params[:editable]}` ohne Prüfung. Mit `editable: true` kommen Zeiten trotz `hidden_results` (`_list_entry_with_times.html.haml`). `ScoreResultChannel` streamt Ergebnisse versteckter Wettkämpfe bei bekannter ID.
  - Fix-Idee: In der Connection `current_user` aus der Warden-Session holen. In `subscribed` den Datensatz laden, `Ability` prüfen (`:read`, für editable `:manage`), sonst `reject`. SimpleAccess-Session beachten.
  - S4-Rest (Admin-Stream mit `include_hidden_lists`) ist mit erledigt.
  - Umsetzung: `ApplicationCable::Connection` identifiziert `current_user` über Warden und reicht die Session durch. `ApplicationCable::Channel#ability_for(competition)` baut die Ability inkl. Gastzugang (`SimpleAccess.from_session`, aus dem Controller herausgezogen, nur lesend – ein WebSocket kann die Session nicht verlängern).
  - `ScoreListChannel`: unbekannte Liste → reject, `editable: true` nur mit `can?(:edit, list)`, sonst `can?(:read, list)` und Liste nicht `hidden`.
  - `ScoreResultChannel`: reject ohne `can?(:read, result)`. Admins (inkl. Gastzugang) abonnieren `score_result_<id>_admin`, der Updater sendet dort das Ergebnis mit `include_hidden_lists` (S4-Rest erledigt), Besucher bekommen weiter die öffentliche Sicht.
  - Geprüft per echtem WebSocket im Browser (Besucher, Admin, Gastzugang). Specs: `spec/channels/` (Rechte-Matrix, Admin-Stream, Warden in der Connection).
  - Nachtrag: Berechtigungen gelten nur beim Abonnieren. Damit schon verbundene Besucher nach dem Verstecken nichts mehr bekommen, prüfen die Updater beim Senden den aktuellen Stand: `ScoreListChannel::Updater` sendet an den öffentlichen Stream nur bei sichtbarem Wettkampf und nicht versteckter Liste (versteckte Zeiten zeigt die öffentliche Zeile ohnehin als „?“), `ScoreResultChannel::Updater` nur bei sichtbarem Wettkampf.
  - Bekannte Grenze: Wird einem Admin der Zugriff entzogen oder läuft ein Gastzugang ab, bleibt ein schon abonnierter Admin-/Bearbeiten-Stream bis zum Neuladen offen.
  - Nachtrag (Produktionsfehler 25.10.2026): Devise `timeoutable` wirft bei abgelaufener Session `throw :warden`, das außerhalb der Warden-Middleware nicht gefangen wird (`UncaughtThrowError` bei jedem Reconnect offener Tabs). `Connection#find_user` fängt es mit `catch(:warden)` und behandelt die Verbindung als nicht angemeldet. Spec: `connection_spec.rb` („treats timed out sessions as anonymous“).
- [x] **S6 Person in fremde Mannschaft über `create_team_name`** (Mittel) – **behoben**
  - `Person#create_team_from_name` (`before_validation`) sucht `Team.find_by(band:, name: create_team_name)` und verbindet mit jeder gleichnamigen Mannschaft. `authorize_person_team!` läuft vorher und sieht das nicht. Wird ein neues Team gebaut, umgeht das zusätzlich `max_teams` und die Team-Berechtigung.
  - Fix-Idee: Für Nicht-Admins `create_team_name` nicht erlauben oder die Auflösung in den Controller ziehen und danach `authorize_person_team!` und die Limit-Prüfung ausführen.
  - Umsetzung (mit Georg abgestimmt): Auflösung aus `Person` (`before_validation`) in `PeopleController#assign_team_from_name` verschoben, läuft vor `authorize_person_team!`. Vergleich in Kleinschreibung ohne Rand-Leerzeichen. Admins wie bisher (vorhandene Mannschaft oder neue). Sonst: eigene Mannschaft (`sub_edit`) wird genutzt, fremde gleichen Namens ergibt Formularfehler „ist bereits angemeldet …“, neue Mannschaft nur bei `can?(:create, team)` (Anmeldung offen) und freiem Mannschafts-Limit; der Anlegende wird Mannschaftsleiter und die Admins bekommen `registration_team`.
  - Dev-Daten: 2 Wertungsgruppen haben schon Mannschaften, die sich nur in der Schreibweise unterscheiden („Elba“/„ELBA“, „Team Firesport germany/Germany“). Dort nimmt der Admin-Weg die erste.
  - Specs: `people_controller_spec.rb` („when a team is given by name“). Neuer Matcher `not_change` in `spec/support/matchers.rb`.
- [x] **S7 Einladungen überleben das Entfernen des Absenders** (Mittel) – **behoben**
  - `UserAccessRequest` / `UserTeamAccessRequest#connect` prüfen nicht, ob der Absender noch Zugriff hat. Einladungen laufen nicht ab und funktionieren auch bei gesperrten Wettkämpfen (`skip_authorize_resource :competition, only: :connect`).
  - Fix-Idee: Beim Entfernen eines Zugriffs die Einladungen dieses Absenders löschen. In `connect` prüfen, ob der Absender noch Zugriff hat. Ablaufdatum einführen.
  - Umsetzung (mit Georg abgestimmt): Concern `InvitationValidity` für beide Einladungs-Models. `expired?`: älter als 30 Tage (`created_at`, keine Migration). `sender_allowed?`: `Ability.new(sender).can?(:create, einladung)`, also „der Absender dürfte diese Einladung jetzt noch verschicken“. Das deckt entzogenen Zugriff und gesperrte Wettkämpfe ab, und Einladungen von Mannschaftsleitern gelten nach Anmeldeschluss nicht mehr (Admin-Einladungen schon). `connect` prüft beides nach dem Token, Meldungen `alerts.invitation_expired` / `alerts.invitation_revoked`.
  - `UserAccess` / `UserTeamAccess` löschen per `after_destroy` die Einladungen des Benutzers, die er danach nicht mehr verschicken dürfte. Die Einladungen werden dabei über die Klasse geladen, sonst kommt `competition.user_accesses` veraltet aus dem Speicher.
  - Specs: `spec/requests/competitions/accesses_controller_spec.rb` und `user_team_accesses_controller_spec.rb` („when invitation is no longer valid“).
  - Offene Reste ausgelagert nach S28.
- [x] **S8 Phishing über Markdown in Mails** (Mittel) – **behoben**
  - `config/initializers/markdown_template_handler.rb` rendert ERB und danach Redcarpet. ERB escaped HTML, aber kein Markdown. Freitexte (`information_request.message`, `access_request.text`, `user_team_access_request.text`, `registration_hint`) erzeugen so Links oder den roten Button (`[[Text]](url)`).
  - Kein Limit für Einladungen an beliebige Adressen.
  - Fix-Idee: Markdown-Sonderzeichen in Benutzertexten escapen (eigener Helper) oder die Texte als Codeblock bzw. Zitat einfügen. Rate-Limit (`rate_limit` in Rails 8) für Einladungen.
  - Umsetzung (mit Georg abgestimmt): Freitexte (`access_request.text`, `user_team_access_request.text`, `information_request.message`, `registration_hint` von Mannschaft/Person) werden mit `EmailMarkdown.render_user_text` getrennt gerendert (`config/initializers/markdown_template_handler.rb`, `EmailUserTextRenderer`): Markdown-Formatierung bleibt, Links/Buttons werden zu Text „Text (URL)“, Bilder zum Alt-Text, HTML wird escaped. Das HTML kommt als einzeiliger `<div>`-Block in die Vorlage (eigene Zeile mit Leerzeilen davor/danach), damit Redcarpet ihn nicht ein zweites Mal rendert.
  - `rate_limit to: 5, within: 1.minute` für `create` in `AccessRequestsController` und `UserTeamAccessRequestsController`, pro Benutzer (sonst IP), danach Umleitung mit `alerts.too_many_requests`. Der Zähler gilt je Einladungsart.
  - Grenze: Mailprogramme verlinken sichtbare URLs im Text teils selbst, das lässt sich serverseitig nicht verhindern. Der Linktext ist aber immer die echte URL.
  - Specs: `spec/mailers/competition_mailer_spec.rb` („user text in mails“), Rate-Limit in `accesses_controller_spec.rb` und `user_team_accesses_controller_spec.rb`.
- [x] **S9 Gast-Login (SimpleAccess) durchprobierbar und sehr mächtig** (Mittel) – **behoben**
  - `SimpleAccessLoginsController#create` ohne `rate_limit`. `SimpleAccess` hat keine Mindestlänge fürs Passwort, der vorgeschlagene Name ist „Admin“ bzw. „Wettkampfrichter“. Gast-Sessions laufen nie ab.
  - `ability.rb#simple_access_abilities` gibt `can(:manage, Competition)`: Gäste können den Wettkampf löschen, Slug und Sichtbarkeit ändern, duplizieren.
  - Fix-Idee: `rate_limit to: 10, within: 1.minute` (Rails 8). Passwort mindestens 8 Zeichen. Gast-Rechte für Löschen, Sichtbarkeit und Veröffentlichen entziehen (mit Georg abstimmen).
  - Umsetzung (mit Georg abgestimmt):
    - `SimpleAccessLoginsController`: `rate_limit to: 10, within: 1.minute, only: :create`, danach Weiterleitung zum Login mit `alerts.too_many_requests`. Zählt pro IP (`request.remote_ip`) im Controller-Cache-Store. Production setzt keinen `cache_store`, also gilt der Rails-Standard (FileStore unter `tmp/cache`). Im Test ist es `:null_store`, der Spec ersetzt `increment` durch einen MemoryStore.
    - `SimpleAccess`: `validates :password, length: { minimum: 8 }, allow_nil: true`. Gilt nur für neue Passwörter, bestehende Gastzugänge bleiben gültig.
    - Gast-Sessions laufen nach 1 Stunde ohne Anfrage ab (gleitend, jede Anfrage verlängert). Die Session speichert jetzt `{ 'id', 'last_seen_at' }` statt nur der ID. Alte Sessions gelten nach dem Deploy als abgemeldet. Der Helper heißt jetzt `current_simple_access` (vorher `simple_access`), dazu `remember_simple_access` / `forget_simple_access` in `CompetitionNestedController`.
    - `ability.rb#simple_access_abilities`: `cannot(%i[destroy change_visibility publish duplicate], Competition, …)`. `VisibilitiesController` prüft `:change_visibility`, `PublishingsController` `:publish`, die Duplikations-Regel `:duplicate`. Für Benutzer mit `UserAccess` ändert sich nichts (`:manage` deckt die neuen Aktionen ab). Links in `showings/show`, `_header` und `presets/index` sind für Gäste ausgeblendet. `can?(:manage, @competition)` bleibt für Gäste wahr.
    - Specs: `spec/requests/competitions/simple_access_logins_controller_spec.rb`, `spec/models/simple_access_spec.rb`.
- [x] **S10 Cookies ohne Secure, kein HSTS** (Mittel) – **behoben**
  - `config/environments/production.rb`: `config.force_ssl` ist auskommentiert, `assume_ssl` fehlt. Klären, wie nginx/Proxy konfiguriert ist, bevor es aktiviert wird.
  - Befund auf dem Server (nginx -T, curl): nginx terminiert TLS, setzt `X-Forwarded-Proto https` für die App und `/cable` und sendet HSTS bereits selbst (`max-age=31536000; includeSubDomains; preload`). „Kein HSTS“ stimmte also nicht. Offen war nur das fehlende `Secure` am Session-Cookie.
  - Umsetzung (mit Georg abgestimmt): `config.assume_ssl = true`, `config.force_ssl = true`, `ssl_options = { hsts: { expires: 365.days, subdomains: true, preload: true } }` – exakt derselbe Header wie von nginx. Achtung: `hsts: false` würde `max-age=0` senden und HSTS im Browser abschalten.
  - Geprüft im Production-Modus (Rack-Anfragen mit Testdatenbank): Cookie `secure`, HSTS identisch zu nginx, `/cable` wird nicht umgeleitet. Kein Spec, weil die SSL-Middleware nur in Production aktiv ist. Nach dem Deploy prüfen: `curl -sI https://feusport.de/ | grep -iE 'set-cookie|strict-transport'` (Cookie mit `secure`, HSTS gleich, ggf. doppelt).
- [x] **S11 Startlisten-Einträge mit fremden Personen/Teams** (Mittel) – **behoben**
  - `Score::ListEntry` validiert nur `:list, :assessment` auf `same_competition`, nicht `entity`. `lists_controller.rb` erlaubt `entity_id`/`entity_type` in `entries_attributes`, und `entity_type` ist nicht auf Person/Team/TeamRelay beschränkt.
  - Fix-Idee: `validates :entity, same_competition: true` (TeamRelay hat keine `competition`, über `team` prüfen) und `entity_type` in einer Allowlist.
  - Umsetzung: `Score::ListEntry::ENTITY_TYPES = %w[Person Team TeamRelay]` mit `validates :entity_type, inclusion:`, dazu `validates :entity, same_competition: true` nur bei erlaubtem Typ (sonst würde die Prüfung selbst eine beliebige Klasse laden). `TeamRelay` delegiert `competition` an sein Team.
  - Altdaten geprüft (Dev-Datenbank, 31.815 Einträge): keine fremden Personen, Mannschaften oder Staffeln, nur die drei erlaubten Typen. Bestehende Einträge bleiben also bearbeitbar.
  - Specs: `spec/models/score/list_entry_spec.rb`, `spec/requests/competitions/score/lists_controller_spec.rb` („entries of other competitions“).
- [x] **S12 Team-Spalten-Werte fremder Wettkämpfe schreiben** (Mittel) – **behoben**
  - `TeamMarkerBlockValue#team_marker_values_attributes=` macht `TeamMarkerValue.find_or_initialize_by(team_marker_id:, team_id:)` mit IDs aus den Params. Es gibt keine Prüfung gegen `@competition`/Band.
  - Fix-Idee: Nur IDs aus `teams` (Band) und `team_markers` (Wettkampf) akzeptieren. `TeamMarkerValue` zusätzlich `validates :team_marker, same_competition: true`.
  - Umsetzung: `TeamMarkerBlockValue#team_marker_values_attributes=` überspringt Einträge, deren `team_id` nicht zu `teams` (Wertungsgruppe) oder deren `team_marker_id` nicht zu `team_markers` (Wettkampf) gehört. Die zusätzliche Validierung entfällt: `TeamMarkerValue#competition` ist an `team_marker` delegiert, sie würde die Spalte mit sich selbst vergleichen. `validates :team, same_competition: true` deckt Team gegen Spalte schon ab. `TeamMarkerValuesController` (Einzelwert) lädt beide über `@competition` und war nicht betroffen. Spec: `spec/requests/competitions/team_marker_block_values_controller_spec.rb` („when ids belong to other bands or competitions“).
- [x] **S13 Duplizieren aus beliebigen Wettkämpfen** (Mittel) – **behoben**
  - `Competitions::Duplication#duplicate_from` nutzt `Competition.find_by(id: duplicate_from_id)`. Die Einschränkung mit `accessible_by` gibt es nur im Select in `presets/index.html.haml`.
  - Fix-Idee: `Competition.accessible_by(ability).find_by(id:)` bzw. im Controller `authorize!(:read, source)`.
  - Umsetzung: `DuplicationsController#assign_duplication` prüft nach dem Laden `authorize!(:read, duplicate_from)` – dieselbe Regel wie die Auswahl (`accessible_by`): öffentliche oder eigene Wettkämpfe. Fremde unsichtbare Wettkämpfe ergeben „Zugriff verweigert“, es wird nichts kopiert. Spec: `duplications_controller_spec.rb` („when source competition is not readable“).
- [x] **S14** (Niedrig) Devise ohne `config.paranoid = true`: Man kann herausfinden, welche E-Mail-Adressen registriert sind. Reset- und Entsperr-Mails lassen sich unbegrenzt auslösen, und mit Lockable kann man fremde Konten sperren. – **behoben (ohne paranoid)**
  - Umsetzung (mit Georg abgestimmt): `config.paranoid` bleibt aus, die bisherigen Meldungen sollen bleiben (E-Mail-Adressen sind also weiter über „nicht gefunden“/„bereits vergeben“ ermittelbar). Neu: `rate_limit` 5/Minute/IP für das Anfordern von Passwort-Reset-, Bestätigungs- und Entsperr-Mails (neue `Users::PasswordsController`, `Users::ConfirmationsController`, `Users::UnlocksController`, in `devise_for` eingetragen) und 10/Minute/IP für Login-Versuche (`Users::SessionsController`). Das bremst Mail-Spam und das Sperren fremder Konten (Lockable: 20 Fehlversuche), verhindert es aber nicht ganz.
  - Specs: `spec/requests/users_spec.rb` („rate limits“).
- [x] **S15** (Niedrig) `config.pepper` steht in `config/initializers/devise.rb` im Repo. ActiveRecord-Encryption hat Fallback-Schlüssel in `config/application.rb` (derzeit kein `encrypts` im Einsatz). Wechsel des Peppers macht alle Passwörter ungültig, also nur mit Plan. – **behoben**
  - Befund: Das Repository ist öffentlich (github.com/Feuerwehrsport/feusport), der alte Pepper also bekannt. Passwörter waren trotzdem per bcrypt (Cost 12) geschützt.
  - ActiveRecord-Encryption: Rückfallwerte entfernt (`ENV.fetch(…, nil)`), ein späteres `encrypts` bricht ohne Variable laut ab.
  - Pepper: `config.pepper` kommt aus `DEVISE_PEPPER`, in Production bricht der Start ohne die Variable ab (auch `assets:precompile` beim Deploy). `LegacyPepperSupport` (in `User`) prüft bei Fehlschlag mit dem alten, öffentlichen Pepper und speichert bei Erfolg sofort einen Hash mit dem neuen (`update_column`, ohne Callbacks). Ungültige Hashes ergeben `false` statt Exception.
  - **Vor dem Deploy auf dem Server setzen:** `DEVISE_PEPPER` (z. B. `bin/rails secret`). Später, wenn kaum noch alte Hashes übrig sind: `LegacyPepperSupport` entfernen (Betroffene nutzen „Passwort vergessen“). Zählen z. B. per Konsole: wer sich seit dem Deploy nicht angemeldet hat (`last_sign_in_at`).
  - Specs: `spec/models/concerns/legacy_pepper_support_spec.rb`, `users_spec.rb` („sign in with a password hashed with the old pepper“).
- [x] **S16** (Niedrig) `app/models/concerns/exports/score_lists.rb`: `inline_format: true` mit Mannschaftsnamen erlaubt Prawn-Tags (`<link>`, `<font size=…>`) im Startlisten-PDF. Namen vorher escapen. – **behoben**
  - Umsetzung: `prawn_escape` (`Prawn::Text::Formatted::Parser.escape`, escaped `&`, `<`, `>`) für den Mannschafts- bzw. Personennamen und den Wertungsnamen, nur in der PDF-Ausgabe. XLSX und HTML bekommen weiter den Rohtext. Gilt für Startliste und Multi-Liste (beide nutzen `show_export_data`). Die Zielzeiten-Zelle nutzt ebenfalls `inline_format`, enthält aber nur formatierte Zahlen. Spec: `spec/models/exports/pdf/score/list_spec.rb` („escapes prawn markup …“).
- [x] **S17** (Niedrig) `Series::Round#…` ruft `Series::Cup.find_or_create_today!` aus Views/Exports auf: Ein GET legt Datensätze an. `rounds_controller.rb` lädt jede Runde ohne `exists_for(@competition)`. `series_*_round_keys` im ResultsController wird nicht gegen `possible_series_round_keys` geprüft. – **behoben**
  - Teil 1 (GET legt Cups an) ist gewollt, Erklärung von Georg: Ältere Cups kommen per nächtlichem Import von extern, für die Berechnung legt `find_or_create_today!` einen Platzhalter-Cup für den aktuellen Wettkampf an. Er enthält keine Ergebnisdaten (Teilnahmen werden im Speicher berechnet) und wird beim nächtlichen Import (`ImportSuggestionsJob#destroy_old_imports`) gelöscht.
  - Teil 2: `RoundsController#show` lädt nur Runden mit `Series::Round.exists_for(@competition)`, fremde ergeben 404. Vorher konnte jeder per URL Platzhalter-Cups für fremde Runden anlegen, die auf Serienseiten anderer Wettkämpfe am selben Tag als Cup auftauchten und `completed` beeinflussten.
  - Teil 3: `Score::Result#added_series_round_keys_possible` prüft nur **neu hinzugefügte** Serien-Schlüssel gegen `possible_series_round_keys` (Disziplin, Jahr); gespeicherte Schlüssel bleiben gültig, auch wenn es die Serie nicht mehr gibt (Vorgabe von Georg). Leere Werte (`""` vom Checkbox-Hidden-Feld, in 241 Dev-Ergebnissen) werden ignoriert. Zwei Specs mit unstimmigen Testdaten (HL-Ergebnis mit LA-Mannschaftswertung) angepasst.
  - Specs: `spec/models/score/result_spec.rb` („series round keys“), `spec/requests/competitions/series/rounds_controller_spec.rb` („round of another series“).
- [x] **S18** (Niedrig) Zustandsänderungen per GET (CSRF per Link): `bands#edit?move=up/down`, `score/lists#move` mit `list[save]` (unbekannte `entry_id` → 500), `certificates/templates#remove_file` und `#duplicate`, `accesses#edit` (setzt `registration_mail_info`). – **behoben**
  - Umsetzung: Wertungsgruppen verschieben über `PATCH bands/:id/move?direction=up|down` (`edit` zeigt nur noch das Formular). Startliste umsortieren speichert nur per POST (`move` per GET rendert nur), unbekannte `entry_id` werden übersprungen statt 500. Urkunden-Vorlagen: `POST …/duplicate`, `DELETE …/remove_file`. Anmelde-Mail umschalten über `PATCH accesses/:id` (`update` statt `edit`, Route `edit` entfernt). Links per `data-turbo-method`, im Browser geprüft (Turbo sendet PATCH, keine CSP-Verstöße).
  - Specs: GET ändert nichts mehr bzw. ergibt 404, die neuen Methoden funktionieren (`bands_controller_spec`, `certificates/templates_controller_spec`, `accesses_controller_spec`, `score/lists_controller_spec` „saves only via post …“).
- [x] **S19** (Niedrig) Kein Content Security Policy (`config/initializers/content_security_policy.rb` auskommentiert). Die EasyMDE-Vorschau (`app/javascript/_easymde.js`) rendert HTML ohne `sanitizerFunction`. – **behoben**
  - CSP (erzwingend, nicht nur Report-Only): `default-src 'self'`, `script-src 'self'` + hCaptcha (keine Inline-Skripte, keine Event-Handler-Attribute), `object-src 'none'`, `base-uri`/`form-action 'self'`, `img-src 'self' data: blob: https:` (QR-Code, OSM-Kacheln), `connect-src 'self'` + Nominatim + hCaptcha, `frame-src 'self'` + hCaptcha. `style-src` erlaubt `'unsafe-inline'` (37 `style`-Attribute in Views, per `innerHTML` eingefügtes HTML, Turbo-Fortschrittsleiste). Bewusst ohne Nonce: Ein Nonce bei `style-src` würde `'unsafe-inline'` aufheben und machte die Snapshots zufällig. `csp_meta_tag` rendert deshalb ein leeres `<meta name="csp-nonce" />`.
  - Teilen-Button: `onclick` aus `ApplicationHelper#social_share_button_tag` entfernt, stattdessen ein Klick-Listener am Dokument in `app/javascript/application.js`.
  - EasyMDE-Vorschau: `sanitizerFunction` mit DOMPurify (neue Abhängigkeit `dompurify`, per yarn). Der Server rendert weiter mit `escape_html` + `Sanitize`, die Vorschau zeigt rohes HTML deshalb gefiltert statt escaped (nur Darstellung, sicher).
  - `frame-ancestors 'self'` (mit Georg abgestimmt: Einbetten in fremde Seiten ist nicht erlaubt). Nicht `'none'`, weil die Urkunden-Vorschau (`certificates/templates/show`) das eigene PDF per iframe zeigt. Ergänzt das von Rails gesetzte `X-Frame-Options: SAMEORIGIN`. Im Browser geprüft: fremde Seite wird blockiert, eigene Domain lädt.
  - Geprüft im Headless-Chromium gegen den Dev-Server: öffentliche Seiten, Karte, Startliste, Ergebnisse, Registrierung mit hCaptcha, Login, Bearbeiten mit EasyMDE, Startliste als Admin ohne CSP-Verstöße und JS-Fehler. Gegenprobe (eingeschleustes Inline-Skript und `onclick`) wird blockiert. Spec: `spec/requests/application_controller_spec.rb` („content security policy“). Neue Inline-Skripte oder `on…`-Attribute funktionieren ab jetzt nicht mehr.
- [x] **S20** (Niedrig) `score/list_factories_controller.rb` erlaubt `:type`. Ein ungültiger STI-Typ wird vor der Validierung gespeichert und ergibt danach einen 500 (nur eigene Session). – **behoben**
  - Ursache: `type_valid` prüfte den Typ erst ab Schritt `generator_params`. Davor wurde jeder Wert gespeichert (z. B. `Competition`), beim nächsten Laden fand Rails die STI-Klasse nicht.
  - Umsetzung: `validates :type, inclusion: { in: ['Score::ListFactory', *GENERATORS] }` bis vor `generator_params`, danach weiter `type_valid` (strenger, keine doppelte Meldung). Spec: `spec/requests/competitions/score/list_factories_controller_spec.rb` („rejects unknown types in every step“).
- [x] **S21** (Niedrig) `Score::ListCondition` prüft `assessments` nicht auf `same_competition`. Nebenbei: Tippfehler `graeter_than` in `validates :track` dort, die Untergrenze wird also nicht geprüft. – **behoben** (`validates :assessments, same_competition: true`, `greater_than: 0`, Specs in `spec/models/score/list_condition_spec.rb`)
- [x] **S22** (Niedrig) `Team.find(params[:team_id])` in `UserTeamAccessesController#assign_team` und `UserTeamAccessRequestsController#assign_team` ist nicht auf `@competition` beschränkt. – **behoben**
  - Umsetzung: Beide laden jetzt `@competition.teams.find(params[:team_id])`, ein Team aus einem anderen Wettkampf ergibt 404. Vorher ließ sich ein Team von B unter der URL von A aufrufen. Der Schaden war begrenzt, weil die Zugriffsliste über `@competition` filtert und Einladungen per `same_competition` gegen das Team validiert werden, daher nur „Niedrig“. Spec: `spec/requests/competitions/user_team_accesses_controller_spec.rb` („when team belongs to another competition“).
- [x] **S23** (Niedrig) `@hotwired/turbo` 7.3.0 hat GHSA-qppm-g56g-fpvp, Update über turbo-rails 8.x. `bundle-audit` ist sauber. – **behoben**
  - Umsetzung (mit Georg abgestimmt): `@hotwired/turbo-rails` ^8.0.23 (Turbo 8.0.23), dazu `esbuild` ^0.28.2 und `sass` ~1.99.0 (letzte Version für Node 18), `source-map-js` im `yarn.lock` auf 1.2.2 neu aufgelöst. `yarn audit` (inkl. Dev-Abhängigkeiten) meldet nichts mehr.
  - Turbo-8-Prefetch (Vorladen beim Überfahren) per `<meta name="turbo-prefetch" content="false">` im Layout abgeschaltet, im Browser geprüft (mit Gegenprobe). CSP-Seiten, Teilen-Button, EasyMDE, Turbo-Methoden-Links im Browser erneut geprüft.
  - Das neue Sass gibt Farben als `rgb(…)` mit Nachkommastellen statt Hex aus (optisch gleich) und meldet Deprecations (siehe W3).
- [x] **S24** (Niedrig) `fire_sport_statistics/suggestions_controller.rb` ist öffentlich und ohne Rate-Limit. `where_name_like` baut `%a%b%c…%`-Muster, lange Eingaben sind teuer. Nicht-String-Params führen zu 500. – **behoben**
  - Gemessen (Dev, ~3500 Personen/Teams): Kosten wachsen linear, 1000 Zeichen ≈ 0,06–0,12 s, kein exponentielles Backtracking. Das JS fragte bei jedem Tastendruck.
  - Umsetzung (mit Georg abgestimmt): `string_param` nimmt nur Strings an (sonst ignoriert) und kürzt auf 100 Zeichen (wie die Namensspalten). `rate_limit to: 100, within: 1.minute`, danach `[]` statt Fehler. `%`/`_` werden per `sanitize_sql_like` wörtlich gesucht (`Person.where_name_like`, `TeamScopes.like_name_or_short`). JS (`_person_suggestions.js`, `_team_suggestions.js`) fragt erst nach 200 ms Tipppause, im Browser geprüft: 12 Tastendrücke → 1 Anfrage.
  - Spec: `spec/requests/fire_sport_statistics/suggestions_controller_spec.rb` („input handling“).
- [x] **S25** (Niedrig) `score/list_factories_controller.rb#list_factory_params` erlaubt `band_ids: []`, aber weder `Score::ListFactory` noch eine Unterklasse hat `band_ids=`, und keine View sendet den Parameter. Ein manipulierter Request mit `band_ids` endet vermutlich in `ActiveModel::UnknownAttributeError` (500). Fix: `band_ids` aus den Strong Params entfernen. – **behoben** (Überbleibsel entfernt; 500er per Spec bestätigt, jetzt wird der Parameter ignoriert. Spec: `list_factories_controller_spec.rb` „band_ids“)
- [x] **S26** (Niedrig) `Score::ListFactory` hat denselben Tippfehler wie früher `Score::ListCondition` (S21): `validates :track_count, numericality: { …, graeter_than: 0 }`. `track_count` 0 oder negativ wird deshalb nicht abgelehnt. Beim Korrigieren prüfen, ob bestehende Factories/Specs `track_count: 0` nutzen. – **behoben** (`greater_than: 0`, kein Spec nutzte `track_count: 0`, Regressions-Spec in `spec/models/score/list_factory_spec.rb`)
- [x] **S27 Einladungen für fremde Mannschaften anlegen** (Niedrig) (bestätigt per Spec) – **behoben**
  - `UserTeamAccessRequestsController#create`: `load_and_authorize_resource` prüft `:create` auf eine Instanz ohne `team`, und `ability.rb` erlaubt das über `access.team.blank? || …`. `assign_new_resource` setzt das Team erst danach. Jeder angemeldete Benutzer kann so für jede Mannschaft Einladungs-Mails verschicken (Absender ist er selbst).
  - Vor S7 ließ sich damit eine Mannschaft übernehmen (Einladung an eigene Zweit-Adresse, dann `connect`). Seit S7 scheitert das Einlösen an `sender_allowed?`. Es bleiben Mails im Namen von Feusport an beliebige Adressen (siehe S8).
  - Fix-Idee: In `create` nach dem Zuweisen `authorize!(:create, @user_team_access_request)` aufrufen, oder `access.team.blank?` aus der Ability entfernen und das Team vor der Prüfung setzen.
  - Umsetzung: `UserTeamAccessRequestsController#assign_new_resource` ruft nach dem Setzen von Team und Absender `authorize!(:create, resource_instance)` auf (greift für `new` und `create`). `access.team.blank?` bleibt in der Ability, weil `load_and_authorize_resource` die Instanz noch ohne Team prüft. Spec: `user_team_accesses_controller_spec.rb` („when user is not allowed to edit the team“: kein Formular, keine Einladung, keine Mail).
- [x] **S28 Abgelaufene und ungültige Einladungen sind nicht erkennbar** (Niedrig) (Rest aus S7) – **behoben**
  - Die Einladungslisten (`app/views/competitions/accesses/index.html.haml`, `app/views/competitions/user_team_accesses/index.html.haml`) zeigen Einladungen, die nach S7 nicht mehr einlösbar sind (`expired?` oder `!sender_allowed?`), ohne Hinweis an. Admins und Mannschaftsleiter halten sie deshalb für offen.
  - Die Einladungs-Mails (`app/views/competition_mailer/access_request.md`, `user_team_access_request.md`) nennen die 30-Tage-Frist (`InvitationValidity::EXPIRES_IN`) nicht.
  - Fix-Idee: In den Listen abgelaufene bzw. ungültige Einladungen kennzeichnen (z. B. „abgelaufen“) oder ausblenden und alte Einträge aufräumen. In den Mails das Ablaufdatum nennen (`created_at + EXPIRES_IN`).
  - Umsetzung (mit Georg abgestimmt): `InvitationValidity#expires_at` (`created_at + 30 Tage`) und `#validity_status` (`:valid`, `:expired`, `:revoked`). Die Listen zeigen eine Spalte „Gültig bis“ mit Datum bzw. Badge „abgelaufen“ / „nicht mehr gültig“ (`ApplicationHelper#invitation_validity_tag`). Beide Mails nennen das Ablaufdatum unter dem Button.
  - `InvitationValidity::CleanupJob` löscht Einladungen nach der doppelten Gültigkeit (60 Tage, `DELETE_AFTER`) ohne Hinweis per `delete_all`, täglich um 4:37 (`config/recurring.yml`, nur production).
  - Specs: `spec/models/concerns/invitation_validity_spec.rb`, `accesses_controller_spec.rb` („marks invalid invitations in the list“), Mail-Snapshots.
- [x] **S29 Reihenfolge der Wertungsgruppen über alle Wettkämpfe** (Niedrig) (bestätigt im Browser) – **behoben**
  - `Band` nutzt `acts_as_list` ohne `scope: :competition`. Die Positionen sind global durchnummeriert (`WHERE (1 = 1)`). „Nach oben/unten“ tauscht deshalb mit der Nachbarposition eines beliebigen Wettkampfs: In der eigenen Liste ändert sich oft nichts, dafür wird eine Wertungsgruppe eines anderen Wettkampfs umsortiert und dessen `updated_at` berührt. `first?`/`last?` gelten ebenfalls global, die Pfeile sind daher oft fälschlich aktiv.
  - Gefunden bei S18 (gab es mit dem alten GET-Link genauso). Im Dev-System wurde dabei die Position von „Männer“ im Erzgebirgspokal 2026 verschoben, die Reihenfolge innerhalb beider Wettkämpfe blieb gleich.
  - Fix-Idee: `acts_as_list scope: :competition` und per Migration die Positionen je Wettkampf neu durchnummerieren (Reihenfolge beibehalten). Duplizieren/Vorlagen prüfen, die Wertungsgruppen anlegen.
  - In der Dev-Datenbank bestätigt: 1364 Wertungsgruppen mit global eindeutigen Positionen 1–1364, nur 1 von 422 Wettkämpfen begann bei 1.
  - Umsetzung: `acts_as_list scope: :competition`. Migration `20261018090000_renumber_band_positions_per_competition` nummeriert je Wettkampf neu (`ROW_NUMBER() OVER (PARTITION BY competition_id ORDER BY position …)`), nicht umkehrbar. In der Dev-Datenbank geprüft: Reihenfolge je Wettkampf identisch, alle 422 Wettkämpfe lückenlos ab 1. Duplizieren und Vorlagen setzen keine Position selbst, neue Wertungsgruppen landen hinten im eigenen Wettkampf.
  - Im Browser geprüft: Pfeile korrekt (de)aktiviert, Verschieben wirkt sichtbar. Spec: `spec/models/band_spec.rb` („is numbered per competition“).
  - Beim Deploy läuft die Migration einmalig über alle Wertungsgruppen.
- [x] **W2 `rails_log_parser` (eigenes Gem) aktualisieren** – **erledigt**
  - Version 0.1.0: `enumerize`, `json` und `rails` als Abhängigkeiten entfernt, nur noch `activesupport`. Dazu Parser-Abstürze behoben (Folgezeilen ohne Request-Beginn, Label `ANY`) und Rubocop/CI ergänzt.
- [x] **W5 Login-Spec scheitert als erster Request im Prozess** – **behoben**
  - Ursache: Warden kopiert seine Konfiguration zu Beginn jedes Requests (`Warden::Proxy#initialize`: `manager.config.dup`). Devise trägt die Strategien erst beim Laden der Routen ein (`finalize!` → `Devise.configure_warden!`), und die werden seit Rails 8 im Test erst während des ersten Requests geladen. Dieser Request läuft deshalb ohne Strategien und endet mit 401.
  - Fix: `spec/rails_helper.rb` lädt die Routen in `before(:suite)` (`Rails.application.reload_routes_unless_loaded`). Den Spec dreimal einzeln laufen lassen, grün.
  - Development ist nicht betroffen (dort lädt der Reloader die Routen vor Warden, per Runner geprüft), Production lädt eager.

Bereits behoben (Commit „Mehr Validierungen auf gleichen Wettkampf“): `band_id` aus den Team/Person-Params entfernt, `same_competition` für Team#band, Person#band/team, AssessmentRequest#assessment, `authorize_person_team!` im PeopleController.
