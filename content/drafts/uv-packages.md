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

## uv workspace

A uv workspace is a folder that contains multiple Python projects (packages/apps) that are managed together with one top-level configuration.

Workspaces are useful when you have:
- Several related services/packages (e.g. API, worker, common-lib)
- Shared dependencies / shared internal libraries
- Want to develop and test them together

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


### Basic structures:

#### Root `pyproject.toml`

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

#### Members

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
- uv will notice that llm-common is another workspace member.

### Typical commands:

To run a command inside a specific member:
```sh
# Run a FastAPI server defined in api/
uv run --package api uvicorn llm_api.main:app --reload
```

To add a dependency:
```sh
# Add 'redis' to worker/ only
uv add -p worker redis
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

You'll mainly see them in `pyproject.toml` under:
```toml
[tool.uv.sources]
...
```
That section lets you say:
- "For this package, install it from here, not from public PyPI."
- Or "Use this private index URL instead of PyPI."

This is especially useful in:
- Company environments with internal PyPI mirrors
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

### with workspace

Inside a workspace:

- `[tool.uv.workspace]`
    - defines which sub-projects belong to the workspace.
- `[tool.uv.sources]` at the root
    - defines how all members should resolve certain dependencies
    - (PyPI vs git vs local path vs another workspace member).
- `[tool.uv.sources]` inside a member
    - can override the root rules for that member only. 

In a workspace you typically have internal packages that you want to import by name, but you do not want to fetch them from PyPI.
```toml
[project]
name = "albatross"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["bird-feeder", "tqdm>=4,<5"]

[tool.uv.sources]
bird-feeder = { workspace = true }

[tool.uv.workspace]
members = ["packages/*"]
```
- albatross depends on a package called bird-feeder.
- bird-feeder is another workspace member.
- bird-feeder = { workspace = true } tells uv:
> "Satisfy this dependency from the workspace, not from PyPI."

For example:
```txt
file-translate/
  pyproject.toml          # workspace root
  libs/
    translate_common/
      pyproject.toml
  services/
    api/
      pyproject.toml
    worker/
      pyproject.toml
```

We can set `pyproject.toml`:
```toml
# file-translate/pyproject.toml (root)

[project]
name = "file-translate"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
  "translate-common",
]

[tool.uv.workspace]
members = ["libs/*", "services/*"]

[tool.uv.sources]
translate-common = { workspace = true }
```
- `members = ["libs/*", "services/*"]`:
- This just tells uv: "there are other projects inside `libs/` and `services/` — manage them together with me as one workspace".

In `services/api/pyproject.toml`:
```toml
[project]
name = "file-translate-api"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
  "fastapi",
  "uvicorn[standard]",
  "translate-common",   # just normal dependency name
]
```

## Hands-on Example



