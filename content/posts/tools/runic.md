---
weight: 1
title: "Runic: A Terminal Workspace for Builds, Sessions, and Coding Agents"
date: 2026-10-13
draft: false
author: Han
description: "Queue your builds, keep your shells alive, and give every coding agent its own worktree—all from one terminal interface"
tags: ["terminal", "tui", "job queue", "task spooler", "runic", "vim", "tmux", "coding agents", "claude code", "git worktree", "go", "build", "ci"]
categories: ["tools", "runic", "terminal"]
---

**[Runic](https://github.com/Han8931/runic)** is a terminal workspace for commands, sessions, and coding agents. The command is `ru`.

It does three things that usually take three different tools. It **queues your commands** so they run a few at a time instead of all at once. It **keeps shells alive** in a background daemon, so closing the window doesn't kill your work. And it gives coding agents a way to **tell you when they need you**, instead of you discovering it on your next tab-cycle.

<p align="center">
  <img
    src="https://raw.githubusercontent.com/Han8931/han8931.github.io/main/assets/images/runic_demo.gif"
    alt="Runic demo"
    style="max-width: 100%; height: auto; border-radius: 6px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"
  >
</p>

It's written in Go and inspired by [task-spooler](/taskspooler/), which I wrote about here years ago and have been queuing experiments with ever since. Run `ru` with a command to queue it; run `ru` by itself to open the interface.

### What It Does

#### 🧮 Queue It and Forget It

Submitting a job is the shortest thing you'll type all day:

```bash
ru make build
ru -L tests make test
ru -L bench make bench
```

Each one returns a job ID and goes into the queue. Runic runs as many as your **slot count** allows—one by default, raise it with `ru config set slots 4`—and holds the rest. Four test suites submitted at once no longer means four test suites competing for the same eight cores.

Jobs take modifiers for the things you actually need: `-L` for a label, `-D` to depend on another job, `--timeout 30m` to stop a runaway, `--retries 2` for a flaky one, `-m` to attach a note to your future self about why you ran it. `ru -l` prints the queue to stdout, so scripts can read it too—or ask for JSON.

#### 🗂️ Five Views Instead of One Long List

Open the interface with a bare `ru` and you get a bordered three-pane screen: a **Sessions** tree on the left, the **Jobs** table across the top, and a **Details** pane underneath for whatever the cursor is on.

The table has view tabs—**All**, **Running**, **Queued**, **Done**, **Failed**—and `Tab` rolls through them. It sounds like a small thing. It isn't. "What's running right now" and "what broke" are two completely different questions, and most tools make you answer both by squinting at the same list. The **Failed** tab keeps its count visible from every other view, so a red `1` follows you around until you deal with it.

Navigation is Vim's: `j`/`k` to move, `gg`/`G` to jump, `/` to filter, `Space` to select rows the way `ranger` does. `x` kills, `r` reruns, `d` removes. There's a `:` command line too, with Tab completion that knows the difference between command names and their values—`:set sl<Tab>` becomes `:set slots `, and `:sort <Tab>` offers you the sort modes.

#### 📜 Output You Can Actually Read

Press `Enter` on any job and its output opens in a pager. Scroll it, search it with `/` and `n`/`N`, press `i` to overlay the job's metadata.

For a job that's still running, the pager **follows** it—new lines arrive as the job produces them, like `tail -f` with a `q` key. That's the difference between a build system you watch and one you check on. When a test run fails, you press `Enter` on the red row and read the failure, instead of hunting for a log file.

(Runic keeps those log files anyway, in `$TMPDIR` by default, and cleans them up when their job leaves the queue.)

#### 🧵 Shells That Outlive the Window

A **session** is a named workspace with its own shells and its own jobs, and sessions group into groups. Inside one, the terminal splits into panes, tmux-style: `Ctrl+B |` side by side, `Ctrl+B -` stacked, nested as deep as you like.

The important part is *where* those shells run. They live in the background daemon, not in your terminal emulator. Detach with `Ctrl+B d`, quit Runic entirely, close the window—come back later and your panes, your layout, and anything still running are all there, with recent scrollback replayed. The daemon starts itself the first time you need it and keeps going until you stop it with `ru -K`.

#### 🤖 An Inbox for Your Agents

This is the part I built Runic for.

Running a coding agent in a pane is easy. Running *four* of them is where it falls apart, because a terminal full of agents looks exactly like a terminal full of idle shells. The one that's been blocked on a question for twenty minutes is visually identical to the three that are happily working.

So in Runic, every pane carries a **self-reported attention state**:

```bash
ru mark working                      # busy, needs nothing
ru mark waiting "which schema?"      # blocked on you—the note shows in the tree
ru mark error "tests failed"
ru mark done
```

Sessions roll up to their most urgent pane. Anything waiting or stuck floats to the top of its group with a colored marker and **how long it's been waiting**, and the status bar says `1 need you` from wherever you are in the interface. The session list stops being a wall of identical shells and starts reading like an inbox.

The state is self-reported on purpose. A full-screen agent lives in the alternate screen buffer, where guessing its mood from output is hopeless. Two things do adjust automatically, because they're unambiguous: a shell prompt clears a stale `working` (whatever was running has exited), and opening a pane clears `waiting`—looking at it *is* the acknowledgment.

Agents don't need to know about Runic for this to work. Panes get `RUNIC_SESSION` and `RUNIC_PANE` in their environment, so three hooks in `.claude/settings.json` are enough to make [Claude Code](https://claude.com/claude-code) report itself:

```json
{
  "hooks": {
    "Notification": [
      {"hooks": [{"type": "command", "command": "ru mark waiting \"$(jq -r .message)\" 2>/dev/null || true"}]}
    ],
    "Stop": [
      {"hooks": [{"type": "command", "command": "ru mark done 2>/dev/null || true"}]}
    ],
    "UserPromptSubmit": [
      {"hooks": [{"type": "command", "command": "ru mark working 2>/dev/null || true"}]}
    ]
  }
}
```

The `|| true` keeps the hook harmless when you run the agent outside a Runic pane. And if you'd rather be told without watching the screen at all, `on_attention` fires a command of your choosing on every transition:

```bash
ru config set on_attention '[ "$RUNIC_ATTENTION" = waiting ] && notify-send "runic: $RUNIC_SESSION" "$RUNIC_NOTE"'
```

#### 🌱 One Agent, One Worktree

Two agents editing the same checkout is a bad afternoon. One of them stages a half-finished change, the other runs the tests, and now nobody knows what failed.

A Runic session can own a fresh `git worktree` on its own branch:

```bash
ru session create agent-1 --worktree          # branch "agent-1"
ru session create agent-2 --branch fix/login  # explicit branch
```

In the interface, the **New session** box has a `branch` field—leave it blank for an ordinary session, or name a branch to isolate it. Isolated sessions are marked `⊕` in the tree, panes start inside the worktree, and the pane's status bar shows which branch you're looking at. Each agent gets its own files, its own index, its own branch.

Deleting the session removes its worktree, but **only if it's clean**. If there are uncommitted edits or untracked files, Runic leaves the checkout where it is and lists exactly what would be lost. You have to say `--discard` to throw work away, and it makes you mean it. The branch always survives—that's where the work is.

### Coming from task-spooler

If you've read my [earlier post on task-spooler](/taskspooler/), most of Runic's CLI will already be in your fingers. `ts` queued a job; `ru` queues a job. `-c` cats a job's output, `-C` clears finished ones, `-t` tails, `-k` kills, `-w` waits. Even the old `TS_*` environment variables are still accepted as fallbacks, so an existing setup doesn't have to be rewritten in one sitting.

Two differences are worth knowing before you start typing out of habit:

* **Bare `ru` opens the interface**, where bare `ts` printed the queue. Use `ru -l` when you want the old behavior—in a script, say, or a pipe.
* **Slots are `-P`**, not `ts`'s `-S`—and `-S` now opens the interface, so the old reflex won't error, it'll just do something else. Or set slots for good with `ru config set slots 4`.

Everything task-spooler did for a queue of training runs, Runic still does. What it adds is the rest of the workspace around that queue: a screen you can read the queue *in*, shells that persist, and sessions that know which of them needs you. task-spooler was built for a machine quietly working through a list of experiments. Runic is for a machine you're actively working *in*, next to a few agents doing the same.

### Why a Daemon?

Everything above depends on one architectural choice: `ru` is a single binary that is both client and server. The daemon owns the queue, runs the jobs, and hosts the shells; the interface is just a client that attaches to it. That's why your panes survive quitting, why `ru -l` works from a script in another directory, and why an agent deep inside a pane can run `ru mark waiting` and have the right session light up.

It's also careful about its own upgrades. If a running daemon speaks an older protocol than the `ru` you just installed, it is *never* killed automatically—commands refuse with a version message telling you to finish its work and then `ru -K`. Running jobs and live panes die when you decide, not when a package manager does.

### Getting Started

Runic needs **Go 1.26.1 or later**, and should be installed from a checkout (the module uses a bundled terminal emulator through a local `replace` directive):

```bash
git clone https://github.com/Han8931/runic.git
cd runic
go install ./cmd/ru/
```

Then try the basic loop:

```bash
ru make build          # queue something
ru -L tests make test  # queue something else
ru                     # open the workspace
```

Job execution works on Linux, macOS, and Windows; the interactive shell panes need Linux or macOS.

👉 **[Check out Runic on GitHub](https://github.com/Han8931/runic)**

Your builds get a queue, your shells stop dying with the window, and your agents finally raise their hands.
