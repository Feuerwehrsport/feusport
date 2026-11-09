# Beispiel-Stoppuhr

Simuliert eine Stoppuhr im Terminal und zeigt, wie ein Gerät die API von feusport.de benutzt.
Die API ist unter `/api/docs` beschrieben. Das Programm braucht Node.js ab Version 18 und keine Pakete.

```sh
node examples/stopwatch/stopwatch.mjs
```

Beim Start wählst du den Server. Alternativ gibst du ihn direkt an:

```sh
node examples/stopwatch/stopwatch.mjs http://localhost:3000
```

## Ablauf

1. Auf der Seite **Zugänge** des Wettkampfs einen Gerätezugang anlegen.
2. Den achtstelligen Code im Programm eingeben. Der Token landet pro Server in `.tokens.json`,
   so wie ein echtes Gerät ihn im Flash speichern würde.
3. Startliste wählen und einen Lauf messen.

| Taste            | Funktion                                 |
| ---------------- | ---------------------------------------- |
| `s`              | Lauf starten                             |
| Ziffern, Buchstaben | laufende Zeit eines Ziels stoppen (Anzeige beachten) |
| `Enter`          | Messung beenden, nicht gestoppte Bahnen sind ungültig |
| `z`              | Zufallszeiten statt Messung              |
| `n` / `p`        | nächster / vorheriger Lauf               |
| `l`              | andere Startliste                        |
| `q`              | Beenden                                  |

Achtung: Auf feusport.de werden echte Ergebnisse des gewählten Wettkampfs überschrieben.
