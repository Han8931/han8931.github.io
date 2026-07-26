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

> **📣 What's New:** Gorae's built-in **AI co-reader** has grown up. Chat with your documents across **persistent sessions**, let the assistant **write summaries straight to your library** via tool calling, wire up your own **slash-command skills**, and pull in fresh facts with optional **web search**. Beyond the AI: **Markdown notes with `[[wikilinks]]`** and automatic backlinks, **navigable multi-hit search** that opens a PDF at the exact page, and **built-in color themes** you can switch live with `:theme`. Bring your own model via **OpenAI** or run everything locally with **Ollama**. Existing users: pull the latest release to try it out. Jump to [🤖 Talk to Your Library](#-talk-to-your-library--a-document-ai-in-your-terminal) for details.

Let's be honest: if you are a researcher, developer, or student, your "Downloads" folder is probably a graveyard of dozens of files named `1905.1234.pdf` or `final_draft_v3_REAL_FINAL.pdf`.

We hoard knowledge. We download papers, save technical manuals, and collect dozens of EPUBs we swear we'll read "someday." But actually managing that library? That's usually a painful choice between chaos (files scattered everywhere) or bloat (slow, heavy GUI applications that feel like overkill).

And here's the bigger shift no one's quite naming yet: **we're moving past the era where "reading a paper" meant linearly parsing every page from abstract to conclusion.** With AI, your relationship to a document changes. You don't just *read* a paper anymore—you *interrogate* it. You ask it questions. You pull answers directly out of it. The PDF stops being a static artifact and starts behaving more like a knowledgeable colleague who happens to know this one topic very well.

So a modern library tool shouldn't just *organize* files. It should help you *talk to them*.

<p align="center">
  <img 
    src="https://github.com/Han8931/gorae/blob/main/assets/gorae_final_demo.gif?raw=true" 
    alt="Gorae App Demo" 
    style="max-width: 120%; height: auto; border-radius: 6px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"
  >
</p>

### The TUI Librarian You've Been Waiting For
**Gorae** (고래, meaning *whale*) is a terminal-first librarian for your PDFs, EPUBs, and Markdown notes.

Think of it as **Claude Code, but for your documents**. Just as Claude Code brought a conversational AI partner into the terminal for developers, Gorae brings one to your reading desk. It is designed as a **fast, Vim-friendly alternative to heavy citation managers like Zotero or Mendeley**—with a dash of Obsidian's linked notes—but with a document-aware AI assistant that lives where you already work. Think *Obsidian + Zotero, in your terminal*. Gorae isn't trying to do everything; it's trying to help you organize, find, read, and now *understand* your documents with maximum efficiency and minimum friction.

### Why You'll Love Swimming with Gorae
If you prefer the keyboard over the mouse, Gorae will feel immediately familiar. Here is how it streamlines your everyday reading:

#### ⚡ Navigate at the Speed of Thought
Forget clicking through endless nested folders. Gorae offers Vim-style browsing. Fly through your library with `j` and `k`. It's snappy, responsive, and designed to keep you in your flow state. And if you *do* reach for the mouse now and then, it works out of the box—scroll, click, select.

#### 🧾 Stop Manually Typing Metadata
Bringing new papers into your library shouldn't be a chore. Gorae automatically scans new PDFs for DOIs or arXiv identifiers and fetches the correct titles, authors, and publication years for you.

#### 🤖 Talk to Your Library — A Document AI in Your Terminal
> *The heart of Gorae—and where most of this release's work went.*

This is where Gorae goes beyond a traditional library manager. We're past the point where storing PDFs neatly is enough; the real leverage is being able to *pull answers straight out of them*. Just like Claude Code gives you a conversational coding partner inside the terminal, Gorae gives you a conversational *reading* partner—an AI co-reader that understands the documents you've collected.

* **Chat with your documents:** Open a paper and just *ask*. "What's the core contribution?" "How does this method differ from prior work?" "Explain Section 3 like I'm new to the field." No copy-pasting into a browser tab.
* **Grounded in your library (RAG):** Every answer is retrieved from the relevant passages in your indexed documents and cited back—so you're getting *your* sources, not a hallucinated summary of the internet. Ask `/sources` to see exactly what was pulled.
* **Auto-summarize papers:** `/summarize` turns a 30-page paper into a tight summary so you can decide whether it's worth a deep read—and saves it right into the file's note.
* **It writes, not just talks:** With tool calling enabled, the assistant can act on your library—e.g. save a summary as a Markdown note straight into your notes directory. It's an assistant that leaves artifacts behind, not just chat.
* **Persistent sessions:** Conversations auto-save. Resume where you left off, fork a fresh line of thought with `/new`, `/compact` older messages to reclaim context, or `/export` the whole thread to Markdown.
* **Your own skills:** Drop a prompt template as a `.md` file and it becomes a slash command—turn "rewrite this as a literature review" into `/litreview` you can fire any time.
* **Optional web search:** When a question needs something outside your library, Gorae can route it through Brave or Tavily instead of guessing.
* **Bring your own model:** Use **OpenAI** for top-tier quality, or run everything locally through **Ollama** when you're working with sensitive material or want a fully offline setup. Any OpenAI-compatible endpoint works too. Your library, your choice.

It all respects the terminal: `Esc` drops you into a Vim-style navigation mode where you can hop between messages with `j`/`k` and yank answers to your clipboard with `y`. No web app, no browser tab, no context switch.

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
The way we engage with written knowledge is changing. Reading is no longer a one-way street—your documents can answer back, summarize themselves, and surface ideas you didn't know they contained. A good library tool in 2026 should meet you there.

Gorae is open-source and ready for you to try.

👉 **[Check out Gorae on GitHub to get started](https://github.com/Han8931/gorae)**

Stop drowning in PDFs. Get organized, stay in the terminal, and let your library start talking back.




