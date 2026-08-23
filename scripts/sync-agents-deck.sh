#!/bin/sh
# Refresh the published deck under static/agents-deck/ from its source repo.
# The deck is copied verbatim so it behaves exactly as it does locally.
#
# Point this at your local clone of the deck, either way:
#   ./scripts/sync-agents-deck.sh /path/to/deck
#   AGENTS_DECK_SRC=/path/to/deck ./scripts/sync-agents-deck.sh
#
# Set AGENTS_DECK_SRC in your shell profile (not in this repo) to skip the
# argument. Defaults to a sibling clone of the deck repository.
set -eu

SRC="${1:-${AGENTS_DECK_SRC:-../agent-deep-dive}}"
DEST="$(cd "$(dirname "$0")/../static/agents-deck" && pwd)"

if [ ! -f "$SRC/agents-deck.html" ]; then
  echo "agents-deck.html not found in: $SRC" >&2
  echo "pass the deck path as an argument, or set AGENTS_DECK_SRC" >&2
  exit 1
fi

cp "$SRC/agents-deck.html" "$DEST/index.html"
cp "$SRC/deck.css" "$SRC/deck.js" "$DEST/"
mkdir -p "$DEST/assets"
cp "$SRC"/assets/*.png "$DEST/assets/"

echo "deck synced -> static/agents-deck/"
