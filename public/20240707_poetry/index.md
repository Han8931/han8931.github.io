# Dependency Management in Python


# Introduction

**Poetry** is a dependency management and packaging tool in Python, aiming to improve how you define, install, and manage project dependencies.
1. Installation: You can install Poetry through its custom installer script or using package managers. The recommended way is to use their installer script to ensure you get the latest version.
2. Creating a New Project: Use `poetry new <project-name>` to create a new project with a standard layout.
3. Adding Dependencies: Add new dependencies directly to your project using `poetry add <package>`. Poetry will resolve the dependencies and update the `pyproject.toml` and `poetry.lock` files.
4. Installing Dependencies: Running `poetry install` in your project directory will install all dependencies defined in your `pyproject.toml` file.

## Poetry Example

### Setting Up a New Project

To create a new project named `example_project` with Poetry and manage its dependencies:
```bash
poetry new example_project
```
- This command creates a new directory named `example_project` with some initial files, including a `pyproject.toml` file for configuration. 
- The `pyproject.toml` file is what is the most important here. This will orchestrate your project and its dependencies. For now, it looks like this:

```toml
[tool.poetry]
name = "poetry-demo"
version = "0.1.0"
description = ""
authors = ["author <author@xxxxx.xxx>"]
readme = "README.md"
packages = [{include = "poetry_demo"}]

[tool.poetry.dependencies]
python = "^3.7"


[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```
- we are allowing any version of Python 3 that is greater than `3.7.0`.
- If you want to use Poetry only for dependency management but not for packaging, you can use the **non-package mode**i:

```toml
[tool.poetry]
package-mode = false
```
### Add and Install Dependencies
Suppose your project depends on `requests` for making HTTP requests and `pytest` for testing. To add these:
```bash
poetry add requests
poetry add pytest --dev
```
- The `--dev` flag indicates that `pytest` is a development dependency, not required for production.

To remove a package, 
```
poetry remove <package>
```

Running the command below will install all dependencies listed in your `pyproject.toml`:
```bash
poetry install
```
- This also creates a virtual environment for your project if it doesn't already exist.

### Run Your Project

#### Run directly
To run a script or start your project within the Poetry-managed virtual environment:
```bash
poetry run python my_script.py
```
This command ensures that `python` and any other commands are run within the context of your project's virtual environment, using the correct versions of Python and all dependencies.

#### Entry Point

In Poetry, an entry point is a way to specify which Python script should be executed when your package is run. This is particularly useful for creating command-line applications or defining executable scripts that can be run directly from the command line after your package is installed.

To define an entry point in a Poetry project, you use the `[tool.poetry.scripts]` section in your `pyproject.toml` file. This section allows you to map a command name to a Python function, which will be executed when the command is run.

Edit your `pyproject.toml` file to include the `[tool.poetry.scripts]` section. This is where you define your entry point. Add the following lines to the `pyproject.toml` file:

```toml
[tool.poetry.scripts]
greet-app = "greet_app.cli:main"
```
- Here, `greet-app` is the command name, and `greet_app.cli:main` specifies the `main` function in the `cli.py` module inside the `greet_app` package.

#### Shell

Using Virtual Environment Shell: If you frequently run commands, you might find it convenient to activate the Poetry-managed virtual environment shell:
```sh
poetry shell
```
This will activate the virtual environment, and you can run your command without prefixing it with poetry run:
```sh
greet-app 
```
To exit this new shell type `exit`. To deactivate the virtual environment without leaving the shell use `deactivate`.

### Init Method

Instead of creating a new project, Poetry can be used to 'initialise' a pre-populated directory. To interactively create a `pyproject.toml` file in directory `pre-existing-project`:
```
poetry init
```

Then, install it by
```
poetry install
```

To see the information about the project
```
poetry env info
```
- `-p`: prints a path of the virtual environment

By setting a config, you can generate a virtual environment in your projects:

```
poetry config virtualenvs.in-project true
```
   
## Use with Git
Poetry automatically creates a `.gitignore` file for you. It should include entries to ignore the virtual environment directory (`.venv` if you use Poetry's built-in virtual environment management).

Whenever you add or update dependencies, make sure to commit the `pyproject.toml` and `poetry.lock` files:

To clone your project:
```
git clone <your-repository-url>
cd my-project
poetry install
```

