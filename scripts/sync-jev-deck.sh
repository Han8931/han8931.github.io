#!/bin/sh
# Refresh the published Jev deck under static/jev-deck/ from its source folder.
# Both decks are copied verbatim except for the local video link in the RLCD
# deck, which points at the YouTube upload instead of a 15 MB .webm file.
#
# Point this at your local copy of the deck, either way:
#   ./scripts/sync-jev-deck.sh /path/to/jev-tutorial
#   JEV_DECK_SRC=/path/to/jev-tutorial ./scripts/sync-jev-deck.sh
#
# Set JEV_DECK_SRC in your shell profile (not in this repo) to skip the
# argument. Defaults to the presentation folder on this machine.
set -eu

SRC="${1:-${JEV_DECK_SRC:-$HOME/Documents/Presentation/jev-tutorial}}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/static/jev-deck"

if [ ! -f "$SRC/jev-slides.html" ] || [ ! -f "$SRC/rlcd-math-slides.html" ]; then
  echo "jev-slides.html / rlcd-math-slides.html not found in: $SRC" >&2
  echo "pass the deck path as an argument, or set JEV_DECK_SRC" >&2
  exit 1
fi

mkdir -p "$DEST"
cp "$SRC/jev-slides.html" "$DEST/index.html"
sed 's#href="What%20is%20RLCD[^"]*\.webm"#href="https://www.youtube.com/watch?v=xwtG4NY5vIA"#' \
  "$SRC/rlcd-math-slides.html" > "$DEST/rlcd-math-slides.html"

echo "deck synced -> static/jev-deck/"
