#!/usr/bin/env python3
"""Concatenate the GPU tutorial into one Hugo post body.

Rewrites asset paths to /gpu-matmul-assets/..., flattens the cross-file links into
in-page anchors, demotes every heading one level (the post title is the h1),
and drops the per-file navigation furniture.
"""
import os, re, pathlib, sys

# Source tutorial folder: argv[1], then $GPU_TUTORIAL_SRC, then the default below.
SRC = pathlib.Path(sys.argv[1] if len(sys.argv) > 1
                   else os.environ.get("GPU_TUTORIAL_SRC",
                                       "~/Han/coding_notes/CodingNotes/GPUs")).expanduser()
OUT = pathlib.Path(__file__).resolve().parent.parent / "content/posts/ai/gpu-matmul.md"

if not SRC.joinpath("GPU_Matmul_Tutorial.md").is_file():
    sys.exit(f"tutorial not found in: {SRC}\n"
             "pass the folder as an argument, or set GPU_TUTORIAL_SRC")

PARTS = [
    "01-foundations.md", "02-first-kernel.md", "03-tiling-and-measurement.md",
    "04-hardware-details.md", "05-hopper.md", "06-beyond-matmul.md",
    "07-reference.md",
]

def slug(heading: str) -> str:
    s = heading.strip().lower()
    s = "".join(c for c in s if c.isalnum() or c in " -_")
    return s.replace(" ", "-")

# ---- map each part file to the anchor of its own (demoted) title -------------
part_anchor = {}
for name in PARTS:
    first = SRC.joinpath("tutorial", name).read_text().splitlines()[0]
    part_anchor[name] = slug(re.sub(r"^#+\s*", "", first))

BOILER = "Each figure has a short takeaway and an expandable walkthrough."

def rewrite_links(text: str) -> str:
    # assets
    text = text.replace("../figures/", "/gpu-matmul-assets/figures/")
    text = text.replace("(figures/", "(/gpu-matmul-assets/figures/")
    text = text.replace("../cpumemory.pdf", "/gpu-matmul-assets/cpumemory.pdf")
    text = text.replace("(cpumemory.pdf)", "(/gpu-matmul-assets/cpumemory.pdf)")
    text = text.replace("../examples/matmul.cu", "/gpu-matmul-assets/matmul.cu")
    text = text.replace("(examples/matmul.cu)", "(/gpu-matmul-assets/matmul.cu)")
    # cross-file links with a fragment -> bare in-page anchor
    text = re.sub(r"\((?:tutorial/)?0\d-[a-z-]+\.md(#[a-z0-9-]+)\)", r"(\1)", text)
    # cross-file links without a fragment -> that part's own anchor
    def part_link(m):
        return "(#" + part_anchor[m.group(1)] + ")"
    text = re.sub(r"\((?:tutorial/)?(0\d-[a-z-]+\.md)\)", part_link, text)
    # the reading-guide backlink
    text = text.replace("(../GPU_Matmul_Tutorial.md)", "(#reading-path)")
    return text

def demote(text: str) -> str:
    """Add one # to every ATX heading outside fenced code blocks."""
    out, fence = [], None
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            marker = stripped[:3]
            fence = None if fence == marker else (marker if fence is None else fence)
            out.append(line)
            continue
        if fence is None and re.match(r"^#{1,5} ", line):
            line = "#" + line
        out.append(line)
    return "\n".join(out)

chunks = []
seen_boiler = False

# ---- the reading guide becomes the post's own introduction ------------------
root = SRC.joinpath("GPU_Matmul_Tutorial.md").read_text()
root = root.split("\n", 1)[1]                      # drop the h1
root = root.replace("The tutorial has been split into parts so you can learn one layer at a time.",
                    "The tutorial is laid out in parts so you can learn one layer at a time.")
root = root.replace("Start with [Part 1: Numbers, addresses, and memory](tutorial/01-foundations.md).",
                    "Start with [Part 1: Numbers, addresses, and memory](#" + part_anchor[PARTS[0]] + ").")
# Its section headings are already h2, which is the level the part titles land
# on after demotion, so this chunk is not demoted.
chunks.append(rewrite_links(root).strip())

# ---- then every part, in order ---------------------------------------------
for name in PARTS:
    body = SRC.joinpath("tutorial", name).read_text()
    lines = []
    for line in body.splitlines():
        if line.startswith("[Reading guide]"):
            continue                               # per-file prev/next furniture
        if BOILER in line:
            if seen_boiler:
                continue                           # keep the explanation once
            seen_boiler = True
        lines.append(line)
    text = "\n".join(lines).strip()
    # collapse the trailing separator left behind by the stripped nav line
    text = re.sub(r"\n-{3,}\s*$", "", text).strip()
    chunks.append(demote(rewrite_links(text)))

body = "\n\n---\n\n".join(chunks) + "\n"

FRONT = """---
weight: 1
title: "Understanding GPUs: From Memory to Fast Matrix Multiplication"
date: 2026-10-05
draft: false
author: Han
math: true
description: "A gradual tutorial on how GPUs execute programs and why data movement decides performance — from a 4x4 matmul you can do by hand to asynchronous Hopper kernels. Slide deck plus the full written tutorial."
tags: ["GPU", "CUDA", "matmul", "H100", "Hopper", "Tensor Core", "TMA", "WGMMA", "memory hierarchy", "coalescing", "tiling", "roofline", "performance"]
categories: ["GPU", "Performance"]
library:
  css:
    - "css/deck-embed.css"
---

GPUs are usually introduced as machines that do a lot of arithmetic. That framing
makes the hard part invisible. An H100 SXM can issue roughly **989 trillion** bf16
operations per second through its Tensor Cores, while its memory delivers about
**3.35 TB/s** — so if every multiply-add had to fetch both of its inputs from main
memory, memory could keep up with less than **0.2%** of the math. Almost everything
that makes a fast kernel fast is about not being in that situation.

This post has two halves. The deck below is the talk version: 34 slides with two
interactive figures, bilingual EN/한국어, and a provenance stamp on every slide
saying whether its claim comes from documentation, from a calculation done on the
slide, or from someone else's benchmark. Under it is the **full written tutorial**,
which goes considerably deeper — hand calculations, a runnable CUDA example, and
the detailed H100 case study.

<div class="deck-embed">
  <iframe src="/gpu-deck/" title="Understanding GPUs — slide deck" loading="lazy" allowfullscreen></iframe>
</div>

<div class="deck-embed-bar">
  <a class="open" href="/gpu-deck/" target="_blank" rel="noopener">Open deck fullscreen ↗</a>
  <span class="keys"><kbd>←</kbd> <kbd>→</kbd> navigate &nbsp;·&nbsp; <kbd>N</kbd> notes &nbsp;·&nbsp; <kbd>L</kbd> EN / 한국어 &nbsp;·&nbsp; <kbd>F</kbd> fullscreen &nbsp;·&nbsp; <kbd>Home</kbd> <kbd>End</kbd> jump</span>
</div>

Present from the fullscreen link — the deck is a standalone page with no site
chrome. Each slide is addressable by hash, so `/gpu-deck/#16` opens directly on the
roofline explorer, and the position survives a reload. Press <kbd>N</kbd> to expand
the teaching notes, which carry the caveats that do not fit on a slide.

---

"""

OUT.write_text(FRONT + body)
print(f"wrote {OUT}")
print(f"  {len(body.splitlines())} body lines, {len(body)} bytes")
