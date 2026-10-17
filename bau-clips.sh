#!/bin/zsh
# =============================================================================
#  Etappenclips bauen                                      17. Oktober 2026
# =============================================================================
#
#  WARUM DIE BILDRATE SO HOCH IST
#
#  Die Clips werden nicht abgespielt, sie werden gescrubbt: der Scroll setzt
#  die Abspielstelle. Damit ist die Bildrate der Clips eine harte Obergrenze
#  dafuer, wie fluessig die Seite sein kann -- und zwar ausgerechnet beim
#  LANGSAMEN Scrollen, also genau dann, wenn jemand liest.
#
#      neue Bilder je Sekunde = Scrolltempo (px/s) x Clipbilder / Scrollweg (px)
#
#  Eine Etappe belegt 0,9 bis 2,4 Fensterhoehen Scrollweg, auf dem Telefon also
#  rund 800 bis 2000 px. Mit den alten 61 Bildern je Etappe (12/s bei 5,08 s)
#  war das ein neues Bild je 25 gescrollten Pixeln: wer mit gemuetlichen
#  100 px/s liest, bekam VIER Bilder in der Sekunde auf einem Schirm, der
#  90- bis 120-mal auffrischt. Das Bild stand eine Viertelsekunde still und
#  sprang dann um gemessene 3,5 px weiter. Das war das Ruckeln, das Christoph
#  und Marcus gemeldet haben, und keine Performance-Weiche kann es fangen:
#  es ist kein Lastproblem, es war schlicht kein Bild mehr da.
#
#  Mit 72 Bildern/s sind es 358 Bilder je Etappe, also ein neues Bild je
#  4 bis 6 gescrollten Pixeln, und der Sprung liegt im Mittel unter 2 px.
#
#  WER DIE CLIPS NEU RENDERT, MUSS DIESE RECHNUNG WIEDER AUFMACHEN -- und das
#  Totband in tick() in scrollcraft.js pruefen: es muss unter einem Clipbild
#  bleiben (bei 72/s sind das 13,9 ms).
#
#  Die Zwischenbilder rechnet ffmpeg bewegungskompensiert (minterpolate, mci).
#  Das traegt hier, weil die Etappen langsame Kamerafahrten ueber ruhende
#  Motive sind. Bei Schnitten oder schnellen Objektbewegungen waere es nicht
#  zu empfehlen -- dann die Quelle gleich mit hoeherer Bildrate rendern.
#
#  QUELLEN
#  Erwartet wird ein Ordner mit den sieben Etappen im Querformat, 1920x1080,
#  mit dem fertigen Grade, als leg1.mp4 bis leg7.mp4.
#
#  Was ausgeliefert wird, ist aus der Querfassung vom 15.10.2026 gebaut. Die
#  holt man sich so zurueck -- damit baut das Skript genau das nach, was
#  online steht:
#
#      mkdir -p /tmp/quer && for i in 1 2 3 4 5 6 7; do
#        git show 9d4307a:assets/leg$i.mp4 > /tmp/quer/leg$i.mp4; done
#      ./bau-clips.sh /tmp/quer
#
#  Alternativ `out/`, die Originalrenderings (liegen lokal, nicht im Repo).
#  Die sind eine Kompressionsgeneration sauberer, heissen aber anders und
#  sind fuer die Nahtstellen zwischen den Etappen nie geprueft worden:
#
#      leg1 <- 01.mp4        leg5 <- 05-graded.mp4
#      leg2 <- 02.mp4        leg6 <- 06b.mp4
#      leg3 <- 03-graded.mp4 leg7 <- 07.mp4
#      leg4 <- 04.mp4
#
#  NIEMALS assets/ als Quelle nehmen: das waere eine weitere Generation auf
#  bereits interpolierte Clips. Das Skript verweigert das.
#
#  Die Hochkantfassung ist ein mittiger 608x1080-Ausschnitt der Querfassung,
#  auf 720x1280 skaliert -- genau der Ausschnitt, den die bisherigen
#  Handyclips hatten (nachgemessen, mittlere Abweichung unter 0,6 von 255).
# =============================================================================
set -e
cd "$(dirname "$0")"

QUELLE=$1
ZIEL=${2:-assets}

if [[ -z "$QUELLE" ]]; then
  echo "Aufruf: ./bau-clips.sh <Quellordner> [Zielordner]   — siehe Kopf dieser Datei." >&2
  exit 1
fi
if [[ "$QUELLE:A" == "$ZIEL:A" ]]; then
  echo "Quelle und Ziel sind derselbe Ordner. Siehe Kopf dieser Datei." >&2
  exit 1
fi
[[ -d "$QUELLE" ]] || { echo "Quellordner '$QUELLE' fehlt. Siehe Kopf dieser Datei." >&2; exit 1; }

# Nur fuer QUELLE=out: dort heissen die Dateien anders als die Etappen.
typeset -A AUS_OUT
AUS_OUT=( 1 01  2 02  3 03-graded  4 04  5 05-graded  6 06b  7 07 )

# Bildrate je Etappe im Querformat. 72 bekommen die vier Etappen mit der
# schnellsten Kamerafahrt (3, 4, 5, 7) -- bei 48 blieb ihr Bildsprung ueber
# 2 px. Die uebrigen drei sind bei 48 unauffaellig und sparen die Bytes.
# Gemessen per Blockmatching, siehe WEBSITE-STATUS.md.
typeset -A QUER_FPS
QUER_FPS=( 1 48  2 48  3 72  4 72  5 72  6 48  7 72 )

# Hochkantausschnitt fuer das Telefon: mittig, 9:16.
CROP="crop=608:1080:(iw-608)/2:0,scale=720:1280:flags=lanczos"
mi () { echo "minterpolate=fps=$1:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1"; }

for i in 1 2 3 4 5 6 7; do
  if [[ "$QUELLE" == "out" ]]; then q_datei="$QUELLE/${AUS_OUT[$i]}.mp4"
  else                              q_datei="$QUELLE/leg$i.mp4"; fi
  [[ -f "$q_datei" ]] || { echo "fehlt: $q_datei" >&2; exit 1; }

  q=${QUER_FPS[$i]}
  # Keyframe alle 0,33 s. Das Scrubben springt staendig; ein weiter Abstand
  # macht jeden Sprung teuer.
  gq=$(( q / 3 ))

  ffmpeg -v error -i "$q_datei" -vf "$(mi $q)" \
    -c:v libx264 -crf 23 -preset slow -g $gq -keyint_min $gq -sc_threshold 0 \
    -pix_fmt yuv420p -profile:v high -movflags +faststart -an -y "$ZIEL/leg$i.mp4"

  # Telefon: immer 72. Dort ist der Scrollweg je Etappe im Verhaeltnis zur
  # Bildhoehe am laengsten, und dort wurde das Ruckeln gemeldet.
  # Keyframe alle 0,167 s, also doppelt so dicht wie im Querformat: ein
  # Telefon soll nach einem Sprung so wenig wie moeglich nachdekodieren.
  ffmpeg -v error -i "$q_datei" -vf "$CROP,$(mi 72)" \
    -c:v libx264 -crf 27 -preset slow -g 12 -keyint_min 12 -sc_threshold 0 \
    -pix_fmt yuv420p -profile:v high -movflags +faststart -an -y "$ZIEL/leg$i-m.mp4"

  echo "leg$i fertig  (quer ${q}/s, hoch 72/s)"
done
