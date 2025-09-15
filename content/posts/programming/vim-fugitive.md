---
weight: 1
title: "Git with Vim Fugitive: A Streamlined Workflow"
date: 2025-04-13
draft: false
author: Han
description: "Git with Vim Fugitive"
tags: ["git", "vim", "fugitive"]
categories: ["git", "programming", "vim"]
---

If you're working with Git and Vim, [**vim-fugitive**](https://github.com/tpope/vim-fugitive) is an essential plugin that transforms your editor into a full-fledged Git interface. Here's how I use Fugitive to review, stage, and commit changes—without ever leaving Vim.

## Browsing Git History and Logs First

Before jumping into edits, it’s often useful to understand the file’s history or recent project changes.

- `:Git log` — shows the project’s commit history in reverse chronological order  
- `:0Gllog` — shows the history of the current file

To explore who changed what in a file:

```vim
:Git blame
```

Press `<Enter>` on a line to inspect its commit, or press `g?` to see other commands.

---

## Viewing and Comparing Versions of a File

You might want to compare your current changes with previous versions:

- `:Gedit HEAD~2:%` — opens the file as it was 2 commits ago  
- `:Gdiffsplit` — shows the current file against the index (staged version)  
  - Use `:Gvdiffsplit` for vertical splits or `:Ghdiffsplit` for horizontal

In diff mode, use:
- `do` — to obtain changes from the other pane  
- `dp` — to put your changes into the other pane

---

## Making and Reviewing Changes

After edits, you may want to review your local changes:

```vim
:Gdiffsplit
```

This shows differences between the working copy and the staged version. Use this view to double-check before staging.

If you decide to undo your changes:

```vim
:Gread
```

This reverts the buffer to the version from the index or last commit.

---

## Staging and Preparing Commits

Now you’re ready to prepare your changes for commit:

```vim
:Git
```

This opens a status window with:
- Untracked files  
- Modified (unstaged) files  
- Staged files

You can:
- Press `-` to toggle staged/unstaged  
- Press `X` to discard changes  
- Press `dv`, `dh`, or `dd` to open diff views for review

When you’re satisfied, press:
- `cc` to commit staged changes  
- `ca` to amend the previous commit

You’ll get a buffer to write your commit message. Save and close it to finish.

---

## Managing Files and Advanced Commands

Here are more powerful tools from Fugitive:

- `:Gwrite` — stage the file (like `git add`)  
- `:GMove` / `:GRename` — move or rename a file with Git  
- `:GDelete` / `:GRemove` — remove a file and buffer  
- `:Ggrep`, `:Glgrep` — grep across the repository  
- `:GBrowse` — open the current file on GitHub or other providers

You can extend `:GBrowse` with plugins for:
- GitHub: [vim-rhubarb](https://github.com/tpope/vim-rhubarb)  
- GitLab: [fugitive-gitlab.vim](https://github.com/shumphrey/fugitive-gitlab.vim)  
- Others like Bitbucket, Azure DevOps, and Sourcehut

---

## Fugitive Cheat Sheet

Here are some quick facts and commands that make `vim-fugitive` incredibly powerful:

- `:Git` with no arguments opens a summary/status window for the current repo
- `:Gdiffsplit` or `:Gvdiffsplit` opens staged vs working tree versions for side-by-side diff
- `:Gread` reverts local changes (undo-able with `u`)
- `:Gwrite` stages the file (or updates it from history, depending on context)
- `:Git blame` opens interactive blame mode — press `<Enter>` on a line to view its commit, or `g?` to see available options
- `:Gedit HEAD~3:%` opens the current file as it existed 3 commits ago
- `:Ggrep` and `:Glgrep` perform Git-powered searches within the repository

### File Management

- `:GMove` — Perform a `git mv` on the file and rename the buffer
- `:GRename` — Like `:GMove`, but destination is relative to current file
- `:GDelete` — `git rm` + close buffer
- `:GRemove` — `git rm` + keep buffer open

### Web Integration

Use `:GBrowse` to open the current file on your Git hosting provider. It even supports line ranges and works well in visual mode.

Plugins exist for:

- GitHub: [`vim-rhubarb`](https://github.com/tpope/vim-rhubarb)  
- GitLab: [`fugitive-gitlab.vim`](https://github.com/shumphrey/fugitive-gitlab.vim)  
- Bitbucket, Gitee, Azure DevOps, and others also supported.

---

## 🏁 Final Thoughts

Vim Fugitive brings Git right into your fingertips, allowing you to manage version control without ever leaving your editor. Whether you're staging, reviewing diffs, or digging into commit history, Fugitive streamlines your workflow and keeps your focus in code.




