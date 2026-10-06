# Feusport

[![Tests](https://github.com/Feuerwehrsport/feusport/actions/workflows/rubyonrails.yml/badge.svg?branch=main)](https://github.com/Feuerwehrsport/feusport/actions/workflows/rubyonrails.yml)
[![Testabdeckung](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FFeuerwehrsport%2Ffeusport%2Fmain%2Fdoc%2Fsimplecov.json&query=%24.covered_percent&suffix=%25&label=Testabdeckung&color=brightgreen)](doc/simplecov.json)

Dieses Projekt dient der Kommunikation innerhalb der [Feuerwehrsport](https://de.wikipedia.org/wiki/Feuerwehrsport)-Szene in Deutschland. Es soll die Übersicht über Wettkämpfe, Termine und Ergebnisse verbessern.

Die Wettkampf-Planung und -Auswertung ist dabei auf den internationalen Feuerwehrsport zugeschnitten. Es können zwar auch andere Wettkämpfe (z.B. Jugend, Traditionell), aber die Unterstützung ist nicht gegeben.

## Technik

Als grundlegendes Framework wird Ruby on Rails mit einem PostgreSQL-Server verwendet. Im Live-Betrieb läuft es auf einem Debian-Linux-Server, welcher von der [Lichtbit GmbH](https://lichtbit.com) zur Verfügung gestellt wird.

## Geschichte

Vor diesem Projekt gab es die [Feuerwehrsport-Statistik](http://www.feuerwehrsport-statistik.de/) und den [Wettkampf-Manager](https://github.com/Feuerwehrsport/wettkampf-manager). Beide sind mit der Zeit gewachsen und erfüllten nicht mehr die Anforderungen an eine zeitgemäße Wettkampfplanung. Gerade die Statistik-Seite war eigentlich niemals als Planungs-Tool gedacht. Der Wettkampf-Manager war ursprünglich nur für den lokalen Einsatz konzipiert und enthält deswegen wenig Funktionen, die man gut im Internet nutzen kann.
