#!/bin/sh
# Refresh the GPU matmul post from its source tutorial folder.
#
# The post body at content/posts/ai/gpu-matmul.md is GENERATED — do not hand-edit
# it, edit the tutorial and re-run this. The slide deck under static/gpu-deck/ is
# maintained in this repo directly and is not touched here.
#
# Point this at your local tutorial folder, either way:
#   ./scripts/sync-gpu-tutorial.sh /path/to/CodingNotes/GPUs
#   GPU_TUTORIAL_SRC=/path/to/CodingNotes/GPUs ./scripts/sync-gpu-tutorial.sh
#
# Set GPU_TUTORIAL_SRC in your shell profile (not in this repo) to skip the
# argument. Defaults to the notes checkout on this machine.
set -eu

SRC="${1:-${GPU_TUTORIAL_SRC:-$HOME/Han/coding_notes/CodingNotes/GPUs}}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/static/gpu-matmul-assets"

if [ ! -f "$SRC/GPU_Matmul_Tutorial.md" ]; then
  echo "GPU_Matmul_Tutorial.md not found in: $SRC" >&2
  echo "pass the tutorial folder as an argument, or set GPU_TUTORIAL_SRC" >&2
  exit 1
fi

# Assets live under /gpu-matmul-assets/ rather than /gpu-matmul/, because the
# permalink rule (posts = ":contentbasename") already publishes the post itself
# at /gpu-matmul/ and the two would share a directory.
mkdir -p "$DEST/figures"
rm -f "$DEST/figures"/*.svg
cp "$SRC"/figures/*.svg "$DEST/figures/"
cp "$SRC"/examples/matmul.cu "$DEST/matmul.cu"
cp "$SRC"/cpumemory.pdf "$DEST/cpumemory.pdf"

python3 "$ROOT/scripts/build-gpu-post.py" "$SRC"

echo "assets synced -> static/gpu-matmul-assets/ ($(ls "$DEST"/figures/*.svg | wc -l | tr -d ' ') figures)"
