---
weight: 1
title: "Deep Dive into Agents"
date: 2026-08-23
draft: false
author: Han
description: "How agents work and how they're built — the harness around the model: tools, context, permissions, sessions, and five harness designs compared. Full slide deck."
tags: ["Agent", "AI", "LLM", "Claude Code", "pi", "opencode", "DeepSeek Harness", "Hermes", "harness", "MCP", "sandbox", "context window"]
categories: ["AI", "Agent", "LLM"]
library:
  css:
    - "css/deck-embed.css"
---

The word *agent* gets used very loosely — sometimes it means a chatbot with a tool attached, sometimes a long-running autonomous system. This talk uses a narrower engineering definition and then spends its time on the part nobody puts on a leaderboard: **the harness**, the software wrapped around the model call.

The claim in one line: two agents running the same model weights can differ by seven to ten benchmark points, and the difference is entirely the harness. If that holds, choosing an agent is not a model-selection problem — it's a systems-engineering one.

<div class="deck-embed">
  <iframe src="/agents-deck/" title="Deep Dive into Agents — slide deck" loading="lazy" allowfullscreen></iframe>
</div>

<div class="deck-embed-bar">
  <a class="open" href="/agents-deck/" target="_blank" rel="noopener">Open deck fullscreen ↗</a>
  <span class="keys"><kbd>←</kbd> <kbd>→</kbd> navigate &nbsp;·&nbsp; <kbd>L</kbd> EN / 한국어 &nbsp;·&nbsp; <kbd>Home</kbd> <kbd>End</kbd> jump</span>
</div>

Present from the fullscreen link — the deck is a standalone page with no site chrome. Each slide is addressable by hash, so `/agents-deck/#17` opens directly on the Claude Code section, and the position survives a reload.

## What the deck covers

**First principles.** What separates an agent from a chatbot or a script: who selects the next action. Then the loop every agent here reduces to — call the model, execute its tool calls, append results, repeat — and the long list of things that loop deliberately does *not* specify.

**Harness anatomy.** Seven slides on the design axes: one tool for everything versus one tool per job, and what each access model costs; the context window as working memory; why a permission prompt and a sandbox solve different problems; how hooks, skills, MCP and plugins do four different jobs; what a saved session buys you; and where the loop actually runs.

**Five implementations, five bets.**

- **Claude Code** — bet on the model. A single-threaded decision loop with parallel tool execution, tools that refuse rather than guess, scoped memory files riding the cached prefix, and mode → rules → sandbox layering.
- **pi** — start small. Four active tools, a fixed prompt under 1,000 tokens, JSONL session trees, MCP deliberately left out of core so its context cost stays opt-in.
- **opencode** — the agent is a server. Many clients, 75+ providers, and configuration as the primary product surface.
- **DeepSeek Harness** — even the loop is a plugin. Event-driven execution with an append-only log, and four selectable run modes.
- **Hermes** — the agent that remembers. A learning layer of memory, user modeling and reusable skills wrapped around the execution loop.

**My take.** The mechanics converge; the beliefs don't. Each project answers a different question about where intelligence, control and durable state should live.

## Three things to hold loosely

The deck says this up front and it's worth repeating here:

1. **It's a snapshot dated August 2026.** These projects ship weekly — flags, defaults and whole features change. The architectural ideas are more durable than the exact counts.
2. **Claude Code has a closed core.** Some internals come from a leaked build rather than published source, and Anthropic hasn't confirmed them.
3. **The numbers aren't a leaderboard.** The referenced eval is 30 tasks with one model, and not every harness ran on the same settings. Stars measure attention, not quality.

Sources are cited on each slide.
