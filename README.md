# Guide Coding

Landingpage von **Guide Coding**, der Zusammenarbeit von Schmitz Systemarchitektur
und der Some1 IT GmbH.

Eine durchgehende Welt: sieben Etappen, ein einziger ungeschnittener Flug durch
einen Betrieb, vom Zettel auf dem Schreibtisch bis zum Freigabe-Gate. Der Scroll
treibt die Kamera, der Text kommt in der Welt an statt darueber zu scrollen.

Mitten im Flug liegt ein **bedienbarer Entwurf**: derselbe klickbare Prototyp, der
in der Planphase entsteht. Er laeuft mit Beispieldaten, speichert nichts und ist
kein Kundenprojekt.

## Hinweise

- **Die Bildwelt ist KI-generiert** und auf der Seite sichtbar als solche
  gekennzeichnet. Die Portraits sind echte Fotos.
- Die Seite ist absichtlich **nicht fuer Suchmaschinen freigegeben**
  (`robots.txt` und `noindex`).

## Lokal ansehen

Ein beliebiger statischer Server im Projektordner, zum Beispiel:

```bash
python3 -m http.server 4500
# http://localhost:4500
```

## Aufbau

| Pfad | Inhalt |
|---|---|
| `index.html` | die Seite. Eigenes Markup, die Engine wird nur eingebunden |
| `scrollcraft.js` / `.css` | die Scroll-Engine. Nicht projektbezogen aendern |
| `assets/` | die sieben Etappen als mp4, je eine Fassung fuer Rechner und Telefon, plus Poster |
| `img/` | Portraits |
| `demo/entwurf.html` | der bedienbare Beispielentwurf |
| `fonts/` | Montserrat und Source Sans 3, selbst gehostet |

Gebaut mit [scroll-craft](https://github.com/nateherk/nateherk-design).
