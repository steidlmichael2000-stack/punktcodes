# Punktcodes — Codesuche für den Außendienst

**→ [steidlmichael2000-stack.github.io/punktcodes](https://steidlmichael2000-stack.github.io/punktcodes/)**

Schnellsuche über die 655 Punktcodes der Vermessungs-Codeliste. Gedacht für das Handy im
Gelände: Begriff eintippen (»Kabelkanal«), passenden Code ablesen, im Tachymeter vergeben.

Läuft **vollständig offline** — die Codeliste steckt direkt in `index.html`, es wird nichts
nachgeladen.

## Aufs Handy holen

1. Die Seite im Browser öffnen (Chrome auf Android, Safari auf iPhone).
2. Menü → **»Zum Startbildschirm hinzufügen«**.
3. Einmal starten, solange Netz da ist. Danach funktioniert die App im Funkloch weiter.

Ohne Server geht es auch: `index.html` aufs Gerät kopieren und direkt öffnen. Die Datei ist
eigenständig, allerdings gibt es dann kein Startbildschirm-Icon.

## Suchen

| Eingabe | Ergebnis |
|---|---|
| `kabelkanal` | 824, 825, 827 |
| `kabel kanal` | dasselbe — Wortteile in beliebiger Reihenfolge |
| `824` | direkt der Code, Rückwärtssuche |
| `80` | alle Codes, die mit 80 beginnen |
| `gebaeude`, `gebäude`, `gebaude` | identisch — Umlaute egal |
| `baum 0,4` | 904 Laubbaum Ø=0,4 m, 924 Nadelbaum |
| `leuchte` | findet **Lampe** / **Laterne** über die Synonymliste |

Weitere Eigenschaften:

- **Ohne Eingabe steht die vollständige Liste unten** — in Codereihenfolge wie die gedruckte
  Codeliste, zum Durchblättern, wenn der Suchbegriff nicht einfällt.
- **Filterchips** nach Art (Eisenbahnanlagen, Ver-/Entsorgung, …) verkürzen diese Liste auf einen
  Bereich und wirken auch auf *Gemerkt* und *Zuletzt benutzt*.
- **Tippen auf einen Treffer** kopiert die Codenummer und legt sie unter *Zuletzt benutzt* ab.
  Im Feld nutzt man ohnehin immer dieselben 20 Codes.
- **★** heftet einen Code dauerhaft nach oben (*Gemerkt*). Die Bestätigung kommt als Einblendung,
  nicht durch Neuaufbau der Seite — sonst wäre beim Blättern die Scrollposition weg. Der Abschnitt
  *Gemerkt* zieht bei der nächsten Suche oder Filteränderung nach.
- `…_allgemein` wird leicht bevorzugt — das ist der übliche Griff, wenn der Spezialfall unklar ist.
- Hell/Dunkel über **◐**; die Auswahl bleibt gespeichert.

Gemerkte Codes, Verlauf und Themewahl liegen im `localStorage` des Geräts, also lokal.

## Datenquelle und Aktualisierung

Grundlage ist `punktcode/punktcodes.csv` aus den BricsCAD-LISP-Tools (Spalten
`Code;Art;Gruppe;Element;Berechnungsart`, Windows-1252). Element und Berechnungsart stammen aus
dem Blatt `gl-survey_2012` der `PUNKTE_Codierung_2012.xlsx`, Art und Gruppe aus der
Bereichshierarchie der PDF-Codierung.

Nach einer Änderung an der Original-CSV:

```powershell
.\build.ps1 -FromSource
```

Das aktualisiert den UTF-8-Snapshot in `data\punktcodes.csv`, baut `index.html` neu und zieht die
Cache-Version in `sw.js` mit. Ohne `-FromSource` wird nur aus dem Snapshot gebaut.

Nach einem Update sehen bereits installierte Geräte die neue Fassung **beim zweiten Start** —
der Service Worker liefert zuerst den Cache aus (damit die App im Funkloch sofort da ist) und holt
die neue Version im Hintergrund.

## Dateien

| Datei | Zweck |
|---|---|
| `index.html` | die gebaute App — **nicht direkt bearbeiten**, wird überschrieben |
| `app.template.html` | Vorlage mit Platzhalter `/*__CODES__*/[]`; hier wird entwickelt |
| `build.ps1` | CSV → JSON → `index.html` |
| `data/punktcodes.csv` | UTF-8-Snapshot der Codeliste |
| `sw.js`, `manifest.json`, `icon-*.png` | Offline-Cache und Installation |
| `make-icons.ps1` | erzeugt die Icons (nur bei Icon-Änderung nötig) |

## Bekannte Macken in der Quelldaten

In der Spalte `Berechnungsart` stehen bei vier Codes Werte, die dort nicht hingehören:

| Code | Element | Berechnungsart |
|---|---|---|
| 433 | Automaten | `554` |
| 435 | Entwerter | `576` |
| 437 | Papierkorb/Müllbehälter | `870` |
| 600 | Gleislatte | `Gleislatte` |

Die App zeigt nur die belastbaren Werte `L`, `H`, `L+H` und `Kontrollmessung` als Kennzeichen an,
die vier Ausreißer bleiben ohne Anzeige. Wer die CSV ohnehin pflegt, kann sie dort auf `-` setzen.
