---
weight: 1
title: "uv workspace: effective management of Python apps"
date: 2025-12-07
draft: false
author: Han
description: "uv workspace tutorial"
tags: ["python", "workspace", "uv", "project management", "uv workspace", "uv tutorial"]
categories: ["uv", "python"]
---

## Understanding uv Workspaces

The official uv website explains workspaces very clearly:
> Inspired by Cargo, a *uv workspace* is a collection of one or more Python packages (workspace members) managed together in a single repo. Each package has its own `pyproject.toml`, but the workspace shares one `lockfile`, keeping dependencies consistent across apps and libraries. Commands like `uv lock` operate on the whole workspace, while `uv run` and `uv sync` default to the workspace root but can target a specific member via `--package` [^1].

In practice, a **uv workspace** is just a directory that contains multiple Python projects (apps and/or libraries) that are managed together with one top-level configuration.

Workspaces are especially useful when:
- You have multiple related apps or services (e.g. API, worker, CLI)
- You maintain one or more **internal libraries** used across those apps
- You want shared dependencies and a single lockfile for consistent environments

For example, you can have:
```txt
llm-platform/
  pyproject.toml          # workspace root
  api/
    pyproject.toml        # FastAPI app
  worker/
    pyproject.toml        # queue consumers, tasks
  common/
    pyproject.toml        # shared utilities, models
```
And uv understands that my-workspace is a workspace root and each project is a member.


## Basic structures:

### Root `pyproject.toml`

At the root, you don't define a Python package (you can, but usually it's just a config container). Most important is the `[tool.uv.workspace]` section:
```toml
[tool.uv.workspace]
members = [
  "api",
  "worker",
  "common",
]
```
- This tells uv: "these subdirs are workspace members".

### Members

Inside `apl/pyproject.toml`:
```toml
[project]
name = "llm-api"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
  "fastapi",
  "uvicorn[standard]"
]

[project.optional-dependencies]
dev = [
  "pytest",
  "httpx",
]
```

Inside `common/pyproject.toml`:
```toml
[project]
name = "llm-common"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
  "pydantic",
]
```

Now `api` can depend on `common` as a normal package:
```toml
[project]
name = "llm-api"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
  "fastapi",
  "uvicorn[standard]",
  "llm-common",          # just use the name
]
```
- uv will notice that `llm-common` is another workspace member.

### Typical commands:

To run a command inside a specific member:
```sh
# Run a FastAPI server defined in api/
uv run --package api uvicorn llm_api.main:app --reload
```

To add a dependency to a member, `cd` into the member package, then:
```sh
# Add 'redis' to worker/ only
uv add redis
```

You can lock dependencies for whole workspace by
```sh
uv lock
```

You can create a member project like this:
```sh
mkdir api common
cd api
uv init --package llm_api
cd ../common
uv init --package llm_common
cd ..
```

## uv sources

A workspace is about project structure:

- It says: "These directories are all part of one big project/monorepo."
- Defined in `[tool.uv.workspace]` in the root `pyproject.toml`.
- All members share:
    - One `uv.lock`
    - One virtualenv (by default)
    - Shared `tool.uv` config

```toml
[project]
name = "my-app"
version = "0.1.0"
dependencies = ["hello-common"]

[tool.uv.workspace]
members = ["libs/*"]
```
- `my-app` is the workspace root.
- Everything under `libs/` (like `libs/hello_common`) is a workspace member.
- uv will install all members as editable when you sync the workspace.

On the other hand, `[tool.uv.sources]` is about where a dependency comes from:
- It enriches `project.dependencies` with alternative sources:

```toml
[project]
name = "my-app"
version = "0.1.0"
dependencies = ["hello-common"]

[tool.uv.workspace]
members = ["libs/*"]

[tool.uv.sources]
hello-common = { workspace = true }
```
- It says *When you see dependency `hello-common`, don't fetch from PyPI — resolve it from my workspace member instead.*
- You can think of sources as:
    - Given a dependency name, where do we install it from?

This is especially useful in:
- Company environments with **internal PyPI mirrors**
- Air-gapped / proxy-heavy setups
- When you want a local wheel dir for speed

For example, you want `my-internal-lib` to come from your company index, not public PyPI.
```toml
[tool.uv.sources]
my-internal-lib = { index = "https://pypi.mycompany.com/simple" }
```

Then in `[project.dependencies]` you just write:
```toml
[project]
name = "my-app"
version = "0.1.0"
dependencies = [
  "my-internal-lib",
]
```

In your uv config file (not `pyproject.toml`), you can set a global index (e.g. corporate mirror):
```config
[package-index]
default = "https://pypi.mycompany.com/simple"
```

## Hands-on Example

Let's use a minimal setup, starting from what `uv init` gives you.

### Starting point

You run:

```bash
uv init uv-ws-practice
cd uv-ws-practice
```

You get:
```text
uv-ws-practice/
├── README.md
├── main.py
└── pyproject.toml
```
- `main.py` is a simple script.

Now let's add a library project `hello_common` under `libs/`.

### Create the library project

From `uv-ws-practice`:

```bash
mkdir -p libs/hello_common
cd libs/hello_common
uv init --package .
cd ../..
```

Now, the project directory looks like this
```text
uv-ws-practice/
├── README.md
├── main.py
├── pyproject.toml          # root
└── libs/
    └── hello_common/       # library project
        ├── README.md
        ├── pyproject.toml
        └── src/
            └── hello_common/
                └── __init__.py
```

Edit `libs/hello_common/src/hello_common/__init__.py`:

```python
def greet(name: str) -> str:
    return f"Hello, {name} from hello_common!"


def main() -> None:
    # For a console script
    print(greet("world"))
```

Edit `libs/hello_common/pyproject.toml` so it would look like:

```toml
[project]
name = "hello-common"  # distribution name
version = "0.1.0"
description = "A small shared library for uv workspace practice."
readme = "README.md"
requires-python = ">=3.10"
dependencies = []

[project.scripts]
hello-common = "hello_common:main"  # console script name

[build-system]
...
```
Now we have:
* Project/distribution: `hello-common`
* Python package: `hello_common` (under `src/hello_common`)
* Script: `hello-common` running `hello_common.main()`.

### 4.3. Turn the root into a workspace and declare the dependency

Open the **root** `pyproject.toml` and make it:

```toml
[project]
name = "uv-ws-practice"
version = "0.1.0"
description = "Root of a uv workspace to practice workspace and sources."
readme = "README.md"
requires-python = ">=3.10"
dependencies = [
    "hello-common",  # ✅ root project depends on the library
]

[build-system]
...

# 1) Workspace members
[tool.uv.workspace]
members = [
    "libs/hello_common",
]

# 2) Source override: "hello-common" comes from *this* workspace
[tool.uv.sources]
hello-common = { workspace = true }
```
* Under `[project]` we say:
  * "This root project *needs* `hello-common` to run."
* Under `[tool.uv.workspace]` we say:
  * "The project at `libs/hello_common` is part of this workspace."
* Under `[tool.uv.sources]` we say:
  * "When resolving the dependency `hello-common`, use the workspace project instead of PyPI."

### Use the library in `main.py`

In the root `main.py`:

```python
from hello_common import greet


def main() -> None:
    print(greet("Workspace"))


if __name__ == "__main__":
    main()
```
Now `main.py` imports the `hello_common` package.

From `uv-ws-practice`:
```bash
uv sync
```
This command
1. Reads the root `pyproject.toml`
2. Sees `dependencies = ["hello-common"]`
3. Sees in `[tool.uv.sources]` that `hello-common` is from the workspace
4. Looks in `[tool.uv.workspace].members` for a matching project (`libs/hello_common`)
5. Resolves dependencies and sets up an environment containing:
   * the root project
   * the `hello-common` library

```bash
uv run python main.py
```

You see:
```text
Hello, Workspace from hello_common!
```

If you had **forgotten** to add `"hello-common"` to `dependencies`, you'd get:

```text
ModuleNotFoundError: No module named 'hello_common'
```

Even though the library *exists* in `libs/hello_common`.
That's the important lesson: **workspace + sources does not automatically make everything importable; you still must depend on it.**

Now try:
```bash
uv run hello-common
```

Because:

* The root env was synced
* Root depends on `hello-common`
* `hello-common` exposes a script called `hello-common`

…`uv` will run the console script from the root project's environment:

```text
Hello, world from hello_common!
```

Alternatively, inside `libs/hello_common`:

```bash
cd libs/hello_common
uv run hello-common
```

Now `uv` uses the library project itself as the current project and still runs the same script.

---

### Why `libs/hello_common/src/hello_common` looks duplicated

The structure:

```text
libs/hello_common/
└── src/
    └── hello_common/
        └── __init__.py
```

can feel redundant.

Here's the separation of roles:

* `libs/hello_common/`
  → Project folder (where `pyproject.toml` lives)

* `src/hello_common/`
  → Python package you actually import:

  ```python
  import hello_common
  ```

This `src` layout is a common best practice because it:

* Prevents accidental imports from the project root during development
* Clearly separates "source code" from tests, configs, etc.

You *could* structure things differently (no `src` directory, different names), but this is a clean default.

---

## 7. Common pitfalls and how to avoid them

### 7.1. "I can't import my workspace library!"

Most common cause:

* You created the library as a workspace member
* You told `uv` about it in `[tool.uv.workspace]` and `[tool.uv.sources]`
* But you **didn't add it to `dependencies`** of the project that imports it

Fix: in the root `pyproject.toml`:

```toml
[project]
dependencies = ["hello-common"]
```

### 7.2. "Why doesn't `uv run -p hello-common hello-common` work?"

Because:

* `-p` == `--python`, i.e., **Python version selector**, *not* "package" or "project".
* `uv run -p hello-common hello-common` is interpreted as:

  > Use a Python interpreter named `hello-common`.

Correct ways:

* From root (if root depends on it):

  ```bash
  uv run hello-common
  ```
* Or from inside the library project:

  ```bash
  cd libs/hello_common
  uv run hello-common
  ```

### 7.3. Name confusion

Keep this map in your head:

* `[project].name = "hello-common"` → dependency name
* `src/hello_common/` → import name: `import hello_common`
* `libs/hello_common/` → project folder in the workspace

Try to keep them *similar* so you don't get lost.

---

## 8. A mental checklist for `uv` workspaces

When you add a new library project and want to use it from the root app:

1. **Create the project**

   * `uv init --package libs/your_lib`
2. **Set a project name** in `libs/your_lib/pyproject.toml`

   * `name = "your-lib"`
3. **Expose a package** inside `src/your_lib/`
4. **Add it as a workspace member** in the root:

   ```toml
   [tool.uv.workspace]
   members = ["libs/your_lib"]
   ```
5. **Add a source override**:

   ```toml
   [tool.uv.sources]
   your-lib = { workspace = true }
   ```
6. **Declare the dependency** in any project that uses it:

   ```toml
   [project]
   dependencies = ["your-lib"]
   ```
7. `uv sync`
8. `uv run python your_script.py` and import away 🚀

---

Note that there are three different *names* floating around:

1. **Project / distribution name**
   * Defined in `pyproject.toml` under `[project].name`
   * Used in dependency lists, e.g.:

     ```toml
     dependencies = ["hello-common"]
     ```
   * This is the name that would appear on PyPI if you published it.

2. **Python package (import) name**
   * This is the thing you write in Python:

     ```python
     import hello_common
     ```
   * It corresponds to a directory with `__init__.py` inside (e.g. `src/hello_common`).

3. **Folder name in your repo**

   * Just your filesystem layout, e.g. `libs/hello_common/`.

They *can* all be different, but that gets confusing fast. In practice:

* You might have:
  * project/distribution: `hello-common` (with a dash)
  * Python package: `hello_common` (with an underscore)
  * folder: `libs/hello_common`
* That's already enough to make your brain itch 😅

`uv init --package .` usually sets things up in a conventional way: a **project folder** containing a **src layout** with the package inside.

For example:

```text
libs/
└── hello_common/              # project folder
    ├── pyproject.toml         # project/distribution: "hello-common"
    └── src/
        └── hello_common/      # Python package: "hello_common"
            └── __init__.py
```

* Project/distribution name: `hello-common`
* Import name: `hello_common`
* Project folder: `libs/hello_common`

[^1]: https://docs.astral.sh/uv/concepts/projects/workspaces/
