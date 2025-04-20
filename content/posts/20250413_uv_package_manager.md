---
weight: 1
title: "All‑in‑One Python Package Manager: UV!"
date: 2025-04-13
draft: false
author: Han
description: "Tutorial for UV python package manager"
tags: ["python", "uv", "package manager", "Virtual Environment"]
categories: ["python", "programming"]
---

## Meet **uv** – A Blazingly Fast, All‑in‑One Python Package Manager

In my last post I dove into **[Poetry](https://han8931.github.io/20240707_poetry/)**, one of the best‑loved modern packaging tools. However, Poetry is just one piece of an toolkit: we still reach for **pip** to install packages, **virtualenv** to isolate them, **pyenv** to juggle Python versions, and maybe **Pipenv** or **pip‑tools** for lock‑files. Each solves its own niche, yet hopping between them adds friction. **uv** removes that friction. This single, project manager—written in Rust and typically **10-1000x** faster-replaces the whole stack: installing Python itself, creating virtual environments, resolving and locking dependencies, and even publishing to PyPI, all behind one concise CLI.

---

## Why Python Packaging Needed a Fresh Start

| Pain Point | Traditional Landscape | How **uv** Fixes It |
|------------|----------------------|---------------------|
| **Tool sprawl** | pip / virtualenv / pyenv / Poetry / pipx | Covers the full workflow |
| **Performance** | Pure‑Python dependency resolution and single‑threaded downloads | Rust core, SAT‑based solver (PubGrub) |
| **Reproducibility** | `requirements.txt` is order‑sensitive & lacks metadata | Deterministic `uv.lock` capturing hashes & markers |

Since its public launch, **uv** already powers **>10 %** of all downloads on PyPI—evidence that developers crave a faster, simpler workflow.

---

## The Lock‑File Landscape at a Glance

Before we dive into **uv**, it helps to remember what _"locking"_ looks like in the existing ecosystem:

1. **Pipenv** – `Pipfile` + `Pipfile.lock`
2. **Poetry** – `pyproject.toml` + `poetry.lock`
3. **pip** – `requirements.txt` created via `pip freeze`

Each of these pins versions, but they store different metadata and often disagree on the resolver algorithm.  **uv** adopts `pyproject.toml` syntax and adds its own **`uv.lock`** that captures exact versions _and_ SHA‑256 hashes for deterministic installs.

---

## From _init_ to _publish_

### 1. Spin‑up

```bash
uv init myapp        # ➊ scaffold project & git repo
```
`uv` chooses a Python interpreter (downloading if necessary), creates `.venv`, writes `.python-version`, and commits a minimal `pyproject.toml`.  

### 2. Add Dependencies

```bash
uv add ruff pytest   # ➋ add linting & tests
```
* **Environment bootstrap** – if `.venv` doesn’t exist, it’s created.
* **Dependency resolution** – the PubGrub SAT solver computes a compatible graph (an NP‑hard problem) in milliseconds.
* **Lockfile update** – `uv.lock` is regenerated atomically so that users can reproduce the exact set.
* **Installation** 

If you Need to remove something,  `uv remove pytest` cleans both the environment _and_ the lockfile.

### 3. Iterate Quickly

```bash
uv run hello.py      # ➌ execute code inside .venv
uv run uvicorn main:app --reload # run uvicorn
uvx ruff check       # ➍ run a CLI tool in a throw‑away env
```

`uv` includes a dedicated interface for interacting with tools. Tools can be invoked without installation using `uv tool run`, in which case their dependencies are installed in a temporary virtual environment isolated from the current project.

Because it is very common to run tools without installing them, a `uvx` alias is provided for `uv tool run` — the two commands are exactly equivalent. For brevity, the documentation will mostly refer to `uvx` instead of `uv tool run`.

### 4. Manage Python Versions Mid‑Stream

```bash
uv python install 3.12.0   # ➎ fetch new interpreter
# switch by editing .python-version, then:
uv sync                    # rebuild .venv deterministically
```
No `sudo`, no global state—interpreters live under `~/.local/share/uv/python`.

### 5. Publish

```bash
uv publish          # ➏ upload to PyPI
```
Zero extra config; metadata comes from `pyproject.toml`.

---

## Workspaces: Multiple Apps, One Cohesive Repo

`uv` can treat a directory tree as a **workspace**.  Sub‑projects share the same interpreter and `.venv`, which is perfect for monorepos housing a library, CLI, and docs site side‑by‑side.

```bash
uv init api            # creates api/ inside current repo
uv init web --no-workspace  # standalone env if you prefer isolation
```
Switching between shared and isolated workflows is a flag away.

---

## Dependency Groups for Dev & Prod

Sometimes you want linting and testing tools _only_ in development.  **uv** follows Poetry’s group syntax:

```bash
uv add --dev pytest ruff      # added under [tool.poetry.group.dev]
uv sync --no-group dev        # skip dev deps
```

---

## Testing with Pytest (and a VS Code Tip)

When you start a project, it's worth deciding up front where your test files will live. I like to keep them in a dedicated tests/ directory that sits alongside the src/ directory rather than inside it. That keeps production code and test code clearly separated and makes the project tree easy to scan:
```sh
project_root/
├── src/
│   ├── main.py
│   └── utils.py
└── tests/
    ├── test_main.py
    └── test_utils.py
```
With this layout, tools such as `pytest` find your tests automatically, and IDEs can apply different run configurations or linters to `src/` and `tests/` without extra setup.

Enable pytest discovery in VS Code by adding:
```jsonc
// .vscode/settings.json
{
  "python.testing.pytestEnabled": true,
  "python.testing.cwd": "${workspaceFolder}/tests"
}
```
Install and run tests:
```bash
uv add --dev pytest
uv run pytest -q
```

---

## Migrating an Existing venv + pip Project

1. Freeze current deps:
   ```bash
   pip freeze > requirements.txt
   ```
2. Initialize uv in place:
   ```bash
   uv init .
   ```
3. Import:
   ```bash
   uv pip install -r requirements.txt
   uv lock
   ```
4. Delete the old `.venv` and enjoy the speed‑up.

### Cheat Sheet

| pip / virtualenv | **uv** |
|------------------|--------|
| `python -m venv .venv` | `uv venv` |
| `pip install pkg` | `uv add pkg` |
| `pip install -r requirements.txt` | `uv pip install -r requirements.txt` |
| `pip uninstall pkg` | `uv remove pkg` |
| `pip freeze` | `uv pip freeze` |
| `pip list` | `uv pip list` |

---

I hope you enjoyed my post!
