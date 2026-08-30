---
weight: 1
title: "UV Tutorial: All‑in‑One Python Package Manager!"
date: 2025-04-13
draft: false
author: Han
description: "Tutorial for UV python package manager"
tags: ["python", "uv", "package manager", "virtual environment"]
categories: ["python", "uv"]
---

> 📝**Update** (2025-09-06): I've added a new section on using system certificates with corporate proxies. It covers why uv may fail with SSL errors at work and how to fix it by making uv trust your system certificates.
>
> 📝**Update** (2026-08-30): Since uv **0.11.0** (March 2026), `--native-tls` is deprecated in favor of `--system-certs`. The section below has been rewritten to use the new flag.

## Meet **uv** – A Blazingly Fast, All‑in‑One Python Package Manager

In my last post, I covered **[Poetry](https://han8931.github.io/poetry/)**. It's a solid dependency manager—but it still leaves you juggling other tools: pip for installs, virtualenv for isolation, pyenv for Python versions, and pip-tools or Pipenv for locks. That bounce between tools adds friction. **uv** removes it. This single, Rust-built project manager—now one of the most popular tools in the Python ecosystem—installs Python, creates virtual environments, resolves and locks dependencies, and even publishes to PyPI, all from one blazing-fast CLI (often 10–1000× faster).

## Why Python Packaging Needed a Fresh Start

| Pain Point | Traditional Landscape | How **uv** Fixes It |
|------------|----------------------|---------------------|
| **Tool sprawl** | pip / virtualenv / pyenv / Poetry / pipx | Covers the full workflow |
| **Performance** | Pure‑Python dependency resolution and single‑threaded downloads | Rust core, SAT‑based solver (PubGrub) |
| **Reproducibility** | `requirements.txt` is order‑sensitive & lacks metadata | Deterministic `uv.lock` capturing hashes & markers |

Since its public launch, **uv** already powers **>10 %** of all downloads on PyPI—evidence that developers crave a faster, simpler workflow.

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
* **Environment bootstrap** – if `.venv` doesn't exist, it's created.
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

Sometimes you want linting and testing tools _only_ in development.  **uv** follows Poetry's group syntax:

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
2. Initialize uv in place and create a virtual environment:
   ```bash
   uv init .
   uv venv
   ```
3. Import:
   ```bash
   uv pip install -r requirements.txt
   uv lock
   ```
4. Delete the old `.venv` and enjoy the speed‑up.

## Managing Private PyPI Repositories with `uv`

If you're using `uv` as your Python package manager, you don't always need to pass `--index-url` when installing packages from a private or internal PyPI mirror (e.g, at your work).
You can configure it globally with
```toml
# ~/.config/uv/uv.toml
[[index]]
url = "http://----" 
default = true
```
Now, you can just run 
```sh
uv add <package-name>
```

## Using `uv` with Private Indexes and Corporate Proxies

If you work in a corporate environment, chances are you're installing packages through an internal PyPI mirror and behind a company proxy. Here's how to make `uv` work smoothly in that setup.

### Configuring a Private PyPI Index

Instead of typing `--index-url` every time you add a package, you can configure your internal index globally:

```toml
# ~/.config/uv/uv.toml
[[index]]
url = "http://repo.mycompany.net/simple"
default = true
```

Now you can simply run:
```sh
uv add numpy
```

and `uv` will fetch packages from your internal repository automatically.

### Setting Proxy Variables

If your network requires a proxy, set these environment variables:

```sh
export HTTP_PROXY="http://proxy.mycompany.net:3128"
export HTTPS_PROXY="http://proxy.mycompany.net:3128"
```

If authentication is required:

```sh
export HTTPS_PROXY="http://username:password@proxy.mycompany.net:3128"
```

And to bypass the proxy for local services:
```sh
export NO_PROXY="localhost,127.0.0.1,.mycompany.net"
```

---

### Why `--system-certs` Matters

`uv` uses **Rustls** for TLS/SSL, and by default it verifies servers against its own **bundled Mozilla root certificates**. That's fine at home, but at work you'll often hit errors like:

```
certificate verify failed: unable to get local issuer certificate
```

This happens because that bundled root store doesn't include your company's custom root certificates—the ones your proxy uses to re-sign traffic.

The fix: tell `uv` to verify against your operating system's certificate store instead:

```sh
uv add --system-certs requests
```

or make it permanent in your config:

```toml
# ~/.config/uv/uv.toml
system-certs = true
```

You can also set it via the environment, which is handy in CI or a shell profile:

```sh
export UV_SYSTEM_CERTS=1
```

Now `uv` respects the certificates your IT team has already installed (the system trust store on Linux, Schannel on Windows, Security.framework on macOS).

> ⚠️ **Note on `--native-tls`:** older guides (including the earlier version of this post) tell you to use `--native-tls` / `native-tls = true` / `UV_NATIVE_TLS`. As of uv **0.11.0** these are **deprecated** in favor of `--system-certs`. They still work and behave identically, so nothing breaks—but the new name is clearer, since uv always uses Rustls and never the `native-tls` library. Prefer `--system-certs` in new setups.

If your company hands you a **specific CA bundle file** rather than installing it system-wide, point `uv` at it directly instead:

```sh
export SSL_CERT_FILE=/path/to/corporate-ca-bundle.pem
```


### Cheat Sheet

| pip / virtualenv | **uv** |
|------------------|--------|
| `python -m venv .venv` | `uv venv` |
| `pip install pkg` | `uv add pkg` |
| `pip install -r requirements.txt` | `uv pip install -r requirements.txt` |
| `pip uninstall pkg` | `uv remove pkg` |
| `pip freeze` | `uv pip freeze` |
| `pip list` | `uv pip list` |

I hope you enjoyed my post!
