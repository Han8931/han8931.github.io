---
weight: 1
title: "Introduction to logging in Python"
date: 2025-05-17
draft: false
author: Han
description: "Logging tutorial"
tags: ["python", "logging", "logger"]
categories: ["python", "programming"]
---


## A gentle, practical introduction to `logging` in Python

---

### Why bother with a dedicated logging library?

- **Prints don’t scale.** `print()` is fine during quick experiments, but real programs need a record that can be filtered, rotated, or shipped elsewhere.
- **Separation of concerns.** You decide *what* to log in your code; `logging` decides *where* and *how* to write it (console, file, etc.).
- **Built-in, no extra dependency.** The standard library’s `logging` module is powerful enough for most applications.

---

### Core concepts

| Concept       | Role in the ecosystem                                                                    | Typical examples                                                                   |
| ------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Logger**    | The entry point your code calls (`logger.info(...)`). You can have many, one per module. | `"__main__"`, `"my_package.worker"`                                                |
| **Handler**   | Decides *where* the record goes.                                                         | `StreamHandler` (stdout), `FileHandler`, `TimedRotatingFileHandler`, `SMTPHandler` |
| **Formatter** | Decides *how* the record looks.                                                          | `'%(asctime)s - %(levelname)s - %(name)s - %(message)s'`                           |

###  A minimal logger

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s | %(message)s"
)

logging.info("Hello, world!")
```
- `basicConfig` is a one-liner good for small scripts.
- In bigger projects, mixing multiple modules / log files, you'll want finer control.

---

### Rotating files at midnight

**Rotating a log file means creating a new log file after a certain time or size limit is reached**. In this case, a new file is created every night at midnight. Only the most recent two log files are kept—yesterday's and today’s—while older ones are deleted automatically.

* Keeps log files from growing forever.
* Eases log shipping/archiving.
* A single command wipes logs older than *n* days.

The `TimedRotatingFileHandler` in the helper below:

| Parameter          | Value                                                                      |
| ------------------ | -------------------------------------------------------------------------- |
| `when="midnight"`  | Rotate every day at 00:00 *server local time*.                             |
| `interval=1`       | Every 1 unit of `when` (here: days).                                       |
| `backupCount=1`    | Keep **one** old file (`log_file.log.2025-05-17`). Older ones are deleted. |
| `encoding="utf-8"` | Avoids surprises with non-ASCII characters.                                |

If you set `backupCount=30`, it will keep:
- Today's log file (log_file.log), and
- The 30 most recent rotated log files (log_file.log.2025-05-17, log_file.log.2025-05-16, ...)

### Drop-in helper: `get_logger`

```python
# logger.py
import logging
from pathlib import Path
from logging.handlers import TimedRotatingFileHandler

LOG_FILE = Path("./logs/log_file.log")
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)  # ensure ./logs/

def get_logger(name: str) -> logging.Logger:
    """Return a module-specific logger configured for daily rotation."""
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    # Prevent adding duplicate handlers if the module is imported repeatedly
    if not logger.handlers:
        handler = TimedRotatingFileHandler(
            filename=LOG_FILE,
            when="midnight",
            interval=1,
            backupCount=1,
            encoding="utf-8",
        )
        formatter = logging.Formatter(
            "%(asctime)s - %(levelname)s - %(name)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        # Block propagation so the same record is not also printed
        logger.propagate = False

    return logger
```

- **`if not logger.handlers:`**: Guarantees that multiple imports don't attach multiple handlers, which would duplicate every line in the output.
- **`logger.propagate = False`**: Stops messages from bubbling up to the *root* logger, so you don't accidentally get console spam when your app also configures a root handler.
    - In other words, "Don’t pass my log message to parent loggers. I'll handle it here."

###  Using the helper in your scripts

```python
# worker.py
from logger import get_logger
logger = get_logger(__name__)

def create_job(job_id: str):
    logger.info(f"Create: JobID: {job_id}")
```

Handling exceptions:

```python
try:
    result = do_something()
except ProcessException as e:
    # Log message plus full traceback
    logger.error("%s: %s", e.code, e.message, exc_info=True)
```
- When you're inside an except block and you want to record not just the error message, but also where exactly the error happened. This is a case where `exc_info` comes in:

```python
try:
    1 / 0
except ZeroDivisionError as e:
    logger.error("An error occurred!", exc_info=True)
```

This will produce a log like:
```sh
2025-05-17 10:23:00 - ERROR - __main__ - An error occurred!
Traceback (most recent call last):
  File "main.py", line 2, in <module>
    1 / 0
ZeroDivisionError: division by zero
```

Without it, you would only see
```sh
2025-05-17 10:23:00 - ERROR - __main__ - An error occurred!
```


