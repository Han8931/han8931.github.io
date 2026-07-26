---
weight: 1
title: "Gorae: Your AI-Powered TUI Librarian"
date: 2026-05-10
draft: false
author: Han
description: "A terminal-first librarian and AI co-reader for your PDFs, EPUBs and Markdowns"
tags: ["terminal", "reference", "reference manager", "tui", "gorae", "pdf", "epub", "markdown", "pdf search", "zotero", "obsidian", "endnote", "vim", "rag", "ollama"]
categories: ["tools", "gorae", "reference manager"]
---

**[Gorae](https://github.com/Han8931/gorae): A terminal-first librarian built for speed, minimalism, and flow—now with a conversational AI assistant baked right in.**

> **📣 What's New:** Gorae's **AI co-reader** has grown up — **persistent chat sessions**, a model that can **write notes into your library** (tool calling), your own **slash-command skills**, and optional **web search**. Plus **Markdown notes with `[[wikilinks]]`**, **navigable search** that opens a PDF at the exact page, and **built-in themes** (`:theme`). Bring your own model with **OpenAI** or run local via **Ollama**. Existing users: pull the latest release.

Let's be honest: if you are a researcher, developer, or student, your "Downloads" folder is probably a graveyard of dozens of files named `1905.1234.pdf` or `final_draft_v3_REAL_FINAL.pdf`.

We hoard knowledge — papers, manuals, dozens of EPUBs we swear we'll read "someday." But managing that library is usually a painful choice between chaos (files scattered everywhere) and bloat (slow, heavy GUI apps that feel like overkill).

And there's a bigger shift underway: with AI, you don't just *read* a paper anymore—you *interrogate* it. The PDF stops being a static artifact and starts behaving like a colleague who happens to know this one topic very well. So a modern library tool shouldn't just *organize* files. It should help you *talk to them*.

<p align="center">
  <img 
    src="https://github.com/Han8931/gorae/blob/main/assets/gorae_final_demo.gif?raw=true" 
    alt="Gorae App Demo" 
    style="max-width: 120%; height: auto; border-radius: 6px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"
  >
</p>

### The TUI Librarian You've Been Waiting For
**Gorae** (고래, meaning *whale*) is a terminal-first librarian for your PDFs, EPUBs, and Markdown notes.

Think of it as **Claude Code, but for your documents** — a conversational AI partner brought to your reading desk. It's a **fast, Vim-friendly alternative to heavy citation managers like Zotero or Mendeley**, with a dash of Obsidian's linked notes and a document-aware AI assistant that lives where you already work. Think *Obsidian + Zotero, in your terminal*. It doesn't try to do everything — just help you organize, find, read, and now *understand* your documents with minimum friction.

### Why You'll Love Swimming with Gorae
If you prefer the keyboard over the mouse, Gorae will feel immediately familiar. Here is how it streamlines your everyday reading:

#### ⚡ Navigate at the Speed of Thought
Forget clicking through endless nested folders. Gorae offers Vim-style browsing. Fly through your library with `j` and `k`. It's snappy, responsive, and designed to keep you in your flow state. And if you *do* reach for the mouse now and then, it works out of the box—scroll, click, select.

#### 🧾 Stop Manually Typing Metadata
Bringing new papers into your library shouldn't be a chore. Gorae automatically scans new PDFs for DOIs or arXiv identifiers and fetches the correct titles, authors, and publication years for you.

#### 🤖 Talk to Your Library — A Document AI in Your Terminal
> *The heart of Gorae—and where most of this release's work went.*

This is where Gorae goes beyond a traditional library manager. Storing PDFs neatly isn't enough anymore; the real leverage is *pulling answers straight out of them*. Gorae gives you a conversational *reading* partner that understands the documents you've collected.

* **Chat, grounded in your library:** Open a paper and just *ask* — "What's the core contribution?", "Explain Section 3 like I'm new to the field." Answers are retrieved from *your* indexed documents and cited back (`/sources`), not hallucinated from the web.
* **Summarize and save:** `/summarize` turns a 30-page paper into a tight summary — and with tool calling on, the assistant can write it straight into your notes as Markdown. It leaves artifacts behind, not just chat.
* **Persistent sessions:** Conversations auto-save. Resume, fork with `/new`, `/compact` to reclaim context, or `/export` to Markdown.
* **Skills & web search:** Drop a prompt template as a `.md` file and it becomes a slash command like `/litreview`. When a question needs something outside your library, route it through Brave or Tavily.
* **Bring your own model:** **OpenAI** for top-tier quality, **Ollama** for fully local and offline, or any OpenAI-compatible endpoint. Your library, your choice.

It all respects the terminal: `Esc` into a Vim-style navigation mode, hop between messages with `j`/`k`, yank answers with `y`. No web app, no browser tab, no context switch.

#### 🔎 Find That One Quote, Instantly
Where was that specific paragraph about transformer attention mechanisms? Don't open ten different PDFs to find it. Gorae's full-text search indexes every document (with stemming, so *running* also finds *run*) and surfaces **every** hit—not just the first. Walk through the matches with `n`/`N`, then hit `Enter` to open the PDF **right at the page where the match lives**. Narrow things down with scoped flags like `-a` (author), `-y` (year), or `--tag`, or query your metadata directly.

#### 🗃️ Get Organized Without the Headache
Gorae helps you tackle your reading list without complicated folder structures.
* **Track Your Progress:** Easily mark papers as *Unread*, *Reading*, or *Read*.
* **Stash for Later:** Use the To-Read queue to keep track of what's next.
* **Hierarchical tags:** Tag a paper `ml/transformers` and searching the `ml/` prefix pulls in the whole family—structure without folders.
* **Link your thinking:** Write Markdown notes with `[[wikilinks]]`, and Gorae builds the backlinks for you—Obsidian-style. Related papers and ideas start connecting themselves.

### Timeless Inspiration
The Gorae logo is inspired by the **Bangudae Petroglyphs** in South Korea—ancient carvings that are among the earliest known depictions of whales.

I wanted Gorae to feel like those engravings: minimal, timeless, and built to last. It doesn't rely on flashy graphics or web engines; it's a solid, handmade tool crafted for a specific purpose. And, just like your favorite terminal setup, it's fully themeable—ships with built-in color themes you can switch live with `:theme`, or tune your own colors, glyphs, and borders to match your aesthetic.

### Ready to Dive In?
Reading is no longer a one-way street — your documents can answer back, summarize themselves, and surface ideas you didn't know they contained. A good library tool in 2026 should meet you there. Gorae is open-source and ready for you to try.

👉 **[Check out Gorae on GitHub to get started](https://github.com/Han8931/gorae)**

Stop drowning in PDFs. Get organized, stay in the terminal, and let your library start talking back.




