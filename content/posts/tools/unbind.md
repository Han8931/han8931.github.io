---
weight: 1
title: "Unbind: Turn PDF Books into Real EPUBs"
date: 2026-08-08
draft: false
author: Han
description: "Turn PDF books into clean, comfortable EPUB 3 ebooks—and repair EPUBs that refuse to open"
tags: ["pdf", "epub", "ebook", "e-reader", "pandoc", "pymupdf", "ocr", "tesseract", "cli", "python", "unbind", "kindle", "kobo"]
categories: ["tools", "unbind", "ebooks"]
---

**[Unbind](https://github.com/Han8931/unbind) turns hard-to-read PDF books into clean, comfortable EPUB 3 ebooks—with one command.**

PDFs are wonderful—right up until you open one on an e-reader. A PDF is a stack of fixed pages designed for paper. On a six-inch screen, that often means tiny text, awkward zooming, and no control over the font. Headers and page numbers can also end up mixed into the text.

What you really want is an EPUB: text that fits your screen, fonts you can resize, and chapters you can jump to. Simply moving the content from one format to another is not enough, though. Running headers, page numbers, broken words, missing chapter links, and scanned pages can all end up in the result.

**Unbind** is designed to improve the book as it converts it. It can use OCR to recover text from scanned pages, rebuild chapters from PDF bookmarks, remove repeated page clutter, repair words split across lines, and add useful metadata and a cover. The goal is not just to produce an EPUB file, but to produce one that is comfortable to read.

### One Command, a Clean Book

```sh
uv run unbind book.pdf
```

That's the whole workflow. Behind that one command is a series of cleanup and recovery steps that turn the PDF's fixed pages into a more polished, flexible ebook:

#### 📑 Chapters That Actually Match the Book

If the PDF has bookmarks, Unbind uses them to rebuild the book's chapter structure. It matches headings to the bookmark hierarchy, adds missing headings for image-only chapter pages, and keeps false positives—such as entries from the book's printed contents page—from cluttering the EPUB navigation. If you prefer the headings exactly as detected, use `--ignore-pdf-toc`.

#### 🧹 No More Running Headers and Page Numbers

Unbind finds lines that repeat at the top or bottom of pages—such as book titles, author names, and page numbers—and removes them while preserving the actual content. It also rejoins words split across line or page breaks. This cleanup is often the difference between a converted file and a book you actually want to read.

#### 🖼️ Covers and Metadata for Free

Unbind reads the book's title and author from the PDF when that information is available. If the title is missing, it uses the filename instead. It also turns the first page—which is often the cover—into an EPUB cover image automatically. You can customize these choices with `--title`, `--author`, and `--cover`, or disable the cover with `--no-cover`.

#### 🔍 Scanned Books Are Detected, Not Silently Butchered

Some PDFs contain real text; others are simply pictures of pages. Before converting, Unbind checks which kind of PDF you have. If the whole book appears to be scanned, it stops early and asks you to run it again with `--ocr`. For non-English books, you can choose any Tesseract language data you have installed—for example, `--ocr-language kor` for Korean. If only some pages need OCR, Unbind warns you before continuing.

#### 📚 Whole Library? Batch It

Point Unbind at a folder and it converts every PDF inside. If one book fails, the rest keep going, and Unbind gives you a summary at the end. Use `--jobs 4` to convert up to four books at once:

```sh
uv run unbind pdfs/ -o epubs/ --jobs 4
```

Want to see or edit the extracted text before it becomes an EPUB? Add `--keep-markdown` to save it as a Markdown file alongside the extracted images.

### The EPUB Doctor: When a Book Refuses to Open

This feature exists because of one particular book that my reader flat-out refused to open. At first glance, the file looked fine: it was packaged correctly and had no DRM. The actual culprit was hidden two pages deep: a tiny piece of HTML written as `&nbsp;`. Some strict EPUB readers don't understand that named entity, and one unreadable page can stop the entire book from opening.

So Unbind also works as an EPUB doctor. Point it at an `.epub` file instead of a PDF:

```sh
uv run unbind book.epub            # diagnose
uv run unbind book.epub --repair   # write book.repaired.epub
```

Unbind checks how the EPUB is packaged, makes sure all required files are present, and opens every content document using strict XML rules. Repair can rebuild the archive, replace troublesome named entities with safe numeric versions (`&nbsp;` → `&#160;`), and recreate a missing `container.xml` when possible. The repaired book looks the same, and your original file is never touched.

Every report also includes brief **notes** about problems repair can't solve. These include DRM encryption, harmless font obfuscation that is often mistaken for DRM, and EPUB-version compatibility. A DRM-locked book, for example, will open only in an authorized reader—but at least Unbind tells you that before you spend hours chasing ghosts. My mystery book went from "won't open" to fixed in one `--repair` run.

### Getting Started

You'll need Python 3.12+, `uv`, [Pandoc](https://pandoc.org/installing.html), and optionally Tesseract for scanned books:

```sh
git clone https://github.com/Han8931/unbind
cd unbind
uv sync
uv run unbind --help
```

### Honest Scope

Unbind is built for *books*—mostly prose organized into chapters. It won't work miracles on multi-column academic papers or heavily designed magazines. Its EPUB check focuses on answering "Why won't this book open?" rather than performing a complete standards audit; use [epubcheck](https://github.com/w3c/epubcheck) when you need that.

But if your shelf of PDF books deserves better than tiny text and constant zooming on an e-ink screen, Unbind will set them free.

MIT licensed. Issues and PRs welcome at [Han8931/unbind](https://github.com/Han8931/unbind).
