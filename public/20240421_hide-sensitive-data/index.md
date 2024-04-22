# How to keep sensitive data in Python?


# How to keep config file?

An app's *config* is everything that is likely to vary between [deploys](https://12factor.net/codebase) (staging, production, developer environments, etc). This includes:
- Resource handles to the database, Memcached, and other [backing services](https://12factor.net/backing-services)
- Credentials to external services such as Amazon S3 or Twitter
- Per-deploy values such as the canonical hostname for the deploy

Apps sometimes store config as constants in the code. This is a violation of twelve-factor, which requires **strict separation of config from code**. Config varies substantially across deploys, code does not.

A litmus test for whether an app has all config correctly factored out of the code is whether the codebase could be made open source at any moment, without compromising any credentials.

**The twelve-factor app stores config in _environment variables_** (often shortened to _env vars_ or _env_). Env vars are easy to change between deploys without changing any code; unlike config files, there is little chance of them being checked into the code repo accidentally; and unlike custom config files, or other config mechanisms such as Java System Properties, they are a language- and OS-agnostic standard.

In a twelve-factor app, env vars are granular controls, each fully orthogonal to other env vars. They are never grouped together as “environments”, but instead are independently managed for each deploy. This is a model that scales up smoothly as the app naturally expands into more deploys over its lifetime.

## Environment Variable

For example, you shouldn't put information directly in your code. 

```python
db_user = 'my_db_user'
db_password = 'my_db_pass_123!'
```

Let's keep the sensitive information in `.bash_profile` as follows:

```sh
export DB_USER="my_db_user"
export DB_PASS='my_db_pass_123!'
```

Then, we can call them by

```python
import os

db_user = os.environ.get('DB_USER')
db_password = os.environ.get('DB_PASS')
```

## dotenv 

### Introduction
Python-dotenv reads key-value pairs from a `.env` file and can set them as environment variables. It helps in the development of applications following the [12-factor](https://12factor.net/) principles.

### Basics

Installation: 
- `pip install python-dotenv`

1. Create `.env` file in your project directory.  
2. Put the data (or variables) in the `.env` file. 
	- e.g, `API_KEY="dafjei304aldkjf20akj"`
3. To load your key, 
	- First, use `load_dotenv()` with `os.getenv("[Your variable]")`
		- e.g., `API_KEY=os.getenv("API_KEY")`
4. Make sure to update `.gitignore` to exclude the `.env` file.

```python
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("API_KEY") or ""
```

