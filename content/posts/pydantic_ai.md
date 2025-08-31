---
weight: 1
title: Agentic AI with Pydantic-AI Part 1.
date: 2025-08-30
draft: false
author: Han
description: A tutorial for Pydantic-AI
tags: ["Python", "Pydantic", "Pydantic-AI", "Agent", "AI"]
categories: ["Python", "Pydantic", "AI"]
---

## Introduction

AI has already changed how we interact with technology. The real shift is happening now with **agents**: AI systems that can reason, make decisions, and take action.

Unlike a chatbot that passively replies, an agent can **break down complex tasks**, call APIs or databases, use tools, and deliver structured results. This is what makes the idea of *Agentic AI* so powerful — it's not just about conversation, it's about **problem-solving with initiative**.

So far, **LangGraph** has emerged as the *de-facto* approach for building complex, stateful agents. But there's also a growing need for something simpler, more ergonomic — and that's where **[Pydantic AI](https://github.com/pydantic/pydantic-ai)** comes in.

Pydantic AI is a **Python agent framework** designed to make it *less painful to build production-grade applications with Generative AI*. Just as **FastAPI** revolutionized web development with an ergonomic design built on **Pydantic validation**, Pydantic AI brings that same "FastAPI feeling" to GenAI app development.

Developers can apply the same best type-safe and Python-centric practices they have used in any other project. Structured responses are validated through Pydantic, dependencies can be injected directly into prompts and tools and for complex scenarios, Pydantic Graph provides a clean way to define control flow without descending into spaghetti code.

In this post — the first in a short series — we'll explore the **basics of Agentic AI and Pydantic AI**, why they matter, and how they're shaping the way we build intelligent systems.

---

## A Minimal Example

Set up with `uv`:
```sh
uv init pydantic_ai_tutorial
cd pydantic_ai_tutorial
uv add pydantic pydantic-ai python-dotenv
```


```python
from pydantic_ai import Agent

agent = Agent(  
    'google-gla:gemini-1.5-flash',
    system_prompt='Be concise, reply with one sentence.',  
)

result = agent.run_sync('Where does "hello world" come from?')  
print(result.output)
# The first known use of "hello, world" was in a 1974 textbook about the C programming language.
```

Here, Pydantic AI sends both the **system prompt** and the **user query** to the LLM. The model then returns a plain text response.

That's a good start — but real agents often need more than text. Let's build something more powerful.

---

## Building a Structured Agent

We start by importing the essentials:

```python
from pydantic import BaseModel
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIChatModel
```

* `BaseModel`: the foundation for defining typed, validated data models.
* `Agent`: the main abstraction for running tasks with an LLM.
* `OpenAIChatModel`: a wrapper for OpenAI-compatible chat models.

---

### Step 1: Define the Schema

Pydantic AI uses a dependency injection system to provide data and services to your agent's system prompts, tools, and output validators. Dependencies can be any Python type, and dataclasses are often a convenient container when you need to include multiple objects.

At the same time, by using a schema with Pydantic, we can enforce a variety of validators. This is important because we want the agent's output to always be a structured object. For example, here's a simple schema with two fields:

```python
from pydantic import BaseModel

class CityLocation(BaseModel):
    city: str
    country: str

# Alternatively, using a dataclass:
# from dataclasses import dataclass
# @dataclass
# class CityLocation:
#     city: str
#     country: str
```
By defining this schema, we force the model to always return a structured object with two fields: `city` and `country`.

Without this, the agent might return a sentence like:
> *“The 2012 Summer Olympics were held in London, United Kingdom.”*

With this schema, the output is always:
```python
CityLocation(city="London", country="United Kingdom")
```

This is **critical for agents** — structured outputs can be passed directly to tools, APIs, or databases without string parsing.

---

### Step 2: Configure the Model

```python
from pydantic_ai.providers.ollama import OllamaProvider

model = OpenAIChatModel(
    model_name='llama3.1:8b',
    provider=OllamaProvider(base_url='http://localhost:11434/v1')
)
```

* `OpenAIChatModel`: wraps the model in an OpenAI-like interface.
* `OllamaProvider`: lets us run a local **Llama 3.1** model.
* Swap this with `"openai:gpt-4o"` and you can run against OpenAI's hosted models with no other changes.

This flexibility is one of Pydantic AI's strengths.

---

### Step 3: Create the Agent

```python
agent = Agent(
    model,   # or "openai:gpt-4o"
    output_type=CityLocation
)
```

This is the **heart of Pydantic AI**:

* `model` → the LLM backend.
* `output_type=CityLocation` → ensures the output always validates against our schema.

---

### Step 4: Run the Agent

```python
result = agent.run_sync('Where were the olympics held in 2012?')
print(result.output)
#> city='London' country='United Kingdom'
print(result.usage())
#> RunUsage(input_tokens=57, output_tokens=8, requests=1)
```

When we run the agent:

* The LLM is called.
* The output is validated against `CityLocation`.
* If the model produces something invalid, Pydantic AI automatically **retries** until it fits the schema.

We also get detailed **usage stats** (tokens, requests) for cost tracking and monitoring.

## Introducing Tools
So far, our agent has taken in text and returned structured data. That's powerful, but real-world agents usually need to do things: query a database, call an API, or run some custom Python code.

In Pydantic AI, this is where tools come in. Tools are simply Python functions you expose to the agent. The agent decides when and how to call them.

Let's look at a simple example:
```python
import random

from pydantic_ai import Agent, RunContext
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv() # Load your API Key

agent = Agent(
    'google-gla:gemini-1.5-flash',  
    deps_type=str,  
    system_prompt=(
        "You're a dice game, you should roll the die and see if the number "
        "you get back matches the user's guess. If so, tell them they're a winner. "
        "Use the player's name in the response."
    ),
)


@agent.tool_plain  
def roll_dice() -> str:
    """Roll a six-sided die and return the result."""
    return str(random.randint(1, 6))


@agent.tool  
def get_player_name(ctx: RunContext[str]) -> str:
    """Get the player's name."""
    return ctx.deps


dice_result = agent.run_sync('My guess is 4', deps='Anne')  
print(dice_result.output)
#> Congratulations Anne, you guessed correctly! You're a winner!
```
---

### Breaking It Down

1. **System Prompt**
   We set the rules of the game in the `system_prompt`: the agent must roll a die and check if the result matches the player's guess.

2. **`roll_dice` Tool** (`@agent.tool_plain`)

   * This is a simple tool which requires no extra context from the agent.
   * It rolls a random number from 1 to 6 and returns it.
   * The agent can call this function whenever it needs a die result.

3. **`get_player_name` Tool** (`@agent.tool`)

   * This tool shows how **dependencies** come into play.
   * We pass the player's name as a dependency (`deps='Anne'`).
   * The tool accesses it through the `RunContext`.
   * This is powerful: you can inject things like database connections, API keys, or user profiles in exactly the same way.

4. **Running the Agent**

   * The user says: *“My guess is 4.”*
   * The agent calls `roll_dice` to simulate the game.
   * It calls `get_player_name` to personalize the response.
   * Finally, it returns a natural sentence, *“Congratulations Anne…”*

---

### Why Tools Matter

Tools are what make an agent **actionable**:

* They let your LLM interact with the real world.
* They allow personalization through dependency injection.
* They keep logic in Python, not just in prompts.

You can test your tools by 
```python
from pydantic_ai import Agent, RunContext

agent = Agent('test', deps_type=int)

@agent.tool
def foobar(ctx: RunContext[int], x: int) -> int:
    return ctx.deps + x

@agent.tool(retries=2)
async def spam(ctx: RunContext[str], y: float) -> float:
    return ctx.deps + y

result = agent.run_sync('foobar', deps=1)
print(result.output)
#> {"foobar":1,"spam":1.0}
```
- The number of retries to allow for this tool, defaults to the agent's default retries, which defaults to 1.

With tools, your agent is no longer just a Q\&A bot — it becomes an **active participant** that can call functions, fetch data, and take action.

## Async 

So far we've built simple agents that return structured outputs and call a few tools. Let's put everything together in a more realistic scenario: an on-call SRE (Site Reliability Engineering) assistant that analyzes service health and suggests a remediation plan.

Instead of “system administrators” doing manual firefighting, Google created a team of engineers who used automation, monitoring, and code to manage reliability at scale. That practice evolved into what we now call SRE.

Imagine you're on call. Users report slow responses and 5xx errors. Instead of digging manually through dashboards and logs, you can ask an agent to do the initial triage for you.

Below is a runnable example:

```python
import os
import asyncio
from dataclasses import dataclass
from typing import Any, Literal

from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.openai import OpenAIProvider
from pydantic_ai.providers.ollama import OllamaProvider

from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")

# ───────────────────────────────
# Mock infra backend
# ───────────────────────────────
class MetricsClient:
    async def cpu_usage(self, service: str) -> float:
        return {"api": 82.4, "worker": 64.1, "db": 29.8}.get(service, 0.0)

    async def error_rate(self, service: str) -> float:
        # errors per minute
        return {"api": 14.0, "worker": 1.2, "db": 0.4}.get(service, 0.0)

    async def recent_logs(self, service: str, level: Literal["ERROR", "WARN"], limit: int = 20) -> list[str]:
        logs = {
            "api": [
                "[ERROR] upstream timeout /v1/translate (llm gateway)",
                "[ERROR] redis timeout queue=llm_jobs",
                "[WARN]  slow request /v1/health 1200ms",
            ],
            "worker": [
                "[WARN]  retry publish job_id=abc",
                "[WARN]  prefetch backlog=40",
            ],
            "db": [
                "[WARN] connection spike from api",
            ],
        }
        out = [l for l in logs.get(service, []) if l.startswith(f"[{level}]")]
        return out[:limit]

# ───────────────────────────────
# Dependencies & output schema
# ───────────────────────────────
@dataclass
class OnCallDeps:
    service: str
    metrics: MetricsClient

class RemediationPlan(BaseModel):
    message: str = Field(description="Human-readable summary for the on-call runbook.")
    severity: Literal["SEV1", "SEV2", "SEV3", "INFO"] = Field(description="Incident severity.")
    notify_oncall: bool = Field(description="Page the primary on-call?")
    actions: list[str] = Field(description="Ordered steps to mitigate the issue.")

# ───────────────────────────────
# Model & Agent
# ───────────────────────────────
# model = OpenAIChatModel("gpt-4o-mini")
model = OpenAIChatModel('gpt-5-nano', provider=OpenAIProvider(api_key=api_key))
# If using Ollama, pick a model that supports tools/function calling, e.g.
# model = OpenAIChatModel(
#     model_name="qwen3:8b",
#     provider=OllamaProvider(base_url="http://localhost:11434/v1"),
# )

oncall_agent = Agent(
    model,
    deps_type=OnCallDeps,
    output_type=RemediationPlan,
    system_prompt=(
        "You are an SRE assistant. Diagnose service incidents using tools before concluding. "
        "Prefer concrete evidence (metrics/logs). Be concise and practical."
    ),
)

# Dynamic system prompt: injects service name at runtime
# The !r in an f-string is a conversion flag that tells Python to use the repr() of the value instead of the default str() when formatting.
@oncall_agent.system_prompt
async def service_context(ctx: RunContext[OnCallDeps]) -> str:
    return f"Target service: {ctx.deps.service!r}. Environment: production."


# ───────────────────────────────
# Tools the agent can call
# ───────────────────────────────
@oncall_agent.tool
async def get_cpu(ctx: RunContext[OnCallDeps]) -> float:
    """Return current CPU utilization percentage for the target service."""
    return await ctx.deps.metrics.cpu_usage(ctx.deps.service)

@oncall_agent.tool
async def get_error_rate(ctx: RunContext[OnCallDeps]) -> float:
    """Return errors-per-minute for the target service."""
    return await ctx.deps.metrics.error_rate(ctx.deps.service)

@oncall_agent.tool
async def get_recent_errors(ctx: RunContext[OnCallDeps]) -> list[str]:
    """Return recent ERROR logs for the target service."""
    return await ctx.deps.metrics.recent_logs(ctx.deps.service, level="ERROR", limit=20)

@oncall_agent.tool
async def get_recent_warns(ctx: RunContext[OnCallDeps]) -> list[str]:
    """Return recent WARN logs for the target service."""
    return await ctx.deps.metrics.recent_logs(ctx.deps.service, level="WARN", limit=20)

# (Optional) A “simulated” action tool (no real side-effects here)
@oncall_agent.tool
async def suggest_restart_plan(ctx: RunContext[OnCallDeps]) -> list[str]:
    """Return a safe, ordered restart plan for the service without executing it."""
    svc = ctx.deps.service
    return [
        f"Drain traffic from {svc} (set canary to 0%)",
        f"Restart {svc} with rolling window=10%, wait=60s",
        f"Warm up cache and check error rate < 2/min",
        "Restore canary to previous level and monitor 15m",
    ]

# ───────────────────────────────
# Demo runs
# ───────────────────────────────
async def main() -> None:
    deps = OnCallDeps(service="api", metrics=MetricsClient())

    result = await oncall_agent.run(
        "Users report 5xx spikes and slow responses. What's happening and what should I do?"
        "\n- Please check metrics and logs first."
        "\n- If CPU and error rate are high, propose a safe mitigation plan.",
        deps=deps,
    )
    print(result.output)

if __name__ == "__main__":
    asyncio.run(main())
```

Example output:
```
message='High CPU (82%) and error rate (14/min) with upstream/redis timeouts in logs. Likely saturation.'
severity='SEV2'
notify_oncall=True
actions=[
  'Enable rate limiting at API gateway (200 RPS per key)',
  'Scale worker pool +2 replicas; verify queue latency',
  'Apply restart plan (drain -> rolling restart -> warmup -> monitor)',
  'Open an incident channel and post status'
]
```


#### Dependencies Injection

```python
@dataclass
class OnCallDeps:
    service: str
    metrics: MetricsClient
```

* **Dependency Injection**: everything the agent needs at runtime (target service + clients).
* You pass this as `deps=` at call time, and the agent receives it via `RunContext`.

```python
class RemediationPlan(BaseModel):
    message: str
    severity: Literal["SEV1","SEV2","SEV3","INFO"]
    notify_oncall: bool
    actions: list[str]
```

* **Typed, validated output** using Pydantic.
* If the LLM returns malformed output, Pydantic AI will **retry** to match this schema—this is what makes agent outputs safe to automate.

#### Agent definition

```python
oncall_agent = Agent(
    model,
    deps_type=OnCallDeps,
    output_type=RemediationPlan,
    system_prompt=(
        "You are an SRE assistant. Diagnose service incidents using tools before concluding. "
        "Prefer concrete evidence (metrics/logs). Be concise and practical."
    ),
)
```

* `deps_type`: tells Pydantic AI what `ctx.deps` will look like (type-safe DI).
* `output_type`: forces the **final answer** to be a `RemediationPlan`.
* `system_prompt`: a *static system prompt*. It defines a baseline behavior.

#### Dynamic system prompt injection

```python
@oncall_agent.system_prompt
async def service_context(ctx: RunContext[OnCallDeps]) -> str:
    return f"Target service: {ctx.deps.service!r}. Environment: production."
```

* Adds **runtime context** to the system prompt (target service/env).
* `!r` formats with `repr()`—handy for quotes and unambiguous display.

#### Tools

```python
@oncall_agent.tool
async def get_cpu(ctx: RunContext[OnCallDeps]) -> float: ...
@oncall_agent.tool
async def get_error_rate(ctx: RunContext[OnCallDeps]) -> float: ...
@oncall_agent.tool
async def get_recent_errors(ctx: RunContext[OnCallDeps]) -> list[str]: ...
@oncall_agent.tool
async def suggest_restart_plan(ctx: RunContext[OnCallDeps]) -> list[str]: ...
```

* Each tool is a **callable capability** exposed to the agent.
* The model decides **when** to call them (tool-use planning) based on your prompt.
* You’ve got:

  * **Read tools**: CPU, error rate, recent error logs.
  * **Advisory tool**: return a step-by-step restart plan (no side effects—great for tutorials).

> Tip: If you later add a *real* action (e.g., scale/rollback), guard it with a `dry_run` flag in `deps` until you add approvals.

#### Running the agent

```python
deps = OnCallDeps(service="api", metrics=MetricsClient())

result = await oncall_agent.run(
    "Users report 5xx spikes and slow responses. What’s happening and what should I do?\n"
    "- Please check metrics and logs first.\n"
    "- If CPU and error rate are high, propose a safe mitigation plan.",
    deps=deps,
)
print(result.output)
```

* Execution flow:

  1. Agent builds the **full system prompt** = base + `service_context(...)`.
  2. Model **plans tool calls** (fetch CPU, error rate, logs).
  3. Model **reasons** over tool results.
  4. Pydantic AI **validates** the model’s draft into `RemediationPlan`. If invalid, it **retries**.
  5. You get a **typed object** you can send to a runbook, Slack, PagerDuty, etc.

## References
- [Pydantic AI](https://ai.pydantic.dev/)
