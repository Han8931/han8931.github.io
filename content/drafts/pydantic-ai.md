---
weight: 1
title: Agentic AI with Pydantic-AI Part 1.
date: 2025-08-31
draft: false
author: Han
description: A tutorial for Pydantic-AI
tags: ["Python", "Pydantic", "Pydantic-AI", "Agent", "AI"]
categories: ["Python", "Pydantic"]
---

## Introduction

AI has already changed how we interact with technology. The real shift is happening now with **agents**: AI systems that can reason, make decisions, and take action.

Unlike a chatbot that passively replies, **an agent can break down a complex task**, call APIs or databases, use tools, and deliver structured results. This is what makes the idea of *Agentic AI* so powerful.

So far, **LangGraph** has emerged as the *de-facto* approach for building complex, stateful agents. But there's also a growing need for something simpler — and that's where **Pydantic AI** comes in. Built on top of `Pydantic`, the widely adopted data-validation library in Python, it inherits a foundation of **simplicity and reliability**. It also encourages **cleaner code** and provides **better documentation** — important aspects when building production-ready systems. By combining the rise of agents with typed, schema-validated outputs, Pydantic AI makes it easier than ever to build robust and trustworthy AI applications.

In this post — the first in a short series — we'll explore the **basics of Agentic AI and Pydantic AI**, why they matter, and how they're shaping the way we build intelligent systems.

---

## A Minimal Example

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

Pydantic AI uses schemas to enforce **structured outputs**. Dependencies can be any Python type, but `BaseModel` is especially useful because it gives you validation for free:

```python
class CityLocation(BaseModel):
    city: str
    country: str
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


## Async 

```python
import asyncio

from dataclasses import dataclass
from typing import Any

from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.ollama import OllamaProvider

from dotenv import load_dotenv


# Load environment variables from .env
load_dotenv()


# Mock database
@dataclass
class Patient:
    id: int
    name: str
    vitals: dict[str, Any]

PATIENT_DB = {
    42: Patient(id=42, name="John Doe", vitals={"heart_rate": 72, "blood_pressure": "120/80"}),
    43: Patient(id=43, name="Jane Smith", vitals={"heart_rate": 65, "blood_pressure": "110/70"}),
}

class DatabaseConn:
    async def patient_name(self, id: int) -> str:
        patient = PATIENT_DB.get(id)
        return patient.name if patient else "Unknown Patient"

    async def latest_vitals(self, id: int) -> dict[str, Any]:
        patient = PATIENT_DB.get(id)
        return patient.vitals if patient else {"heart_rate": 0, "blood_pressure": "N/A"}


@dataclass
class TriageDependencies:
    patient_id: int
    db: DatabaseConn


class TriageOutput(BaseModel):
    response_text: str = Field(description="Message to the patient")
    escalate: bool = Field(description="Should escalate to a human nurse")
    urgency: int = Field(description="Urgency level from 0 to 10", ge=0, le=10)

ollama_model = OpenAIChatModel(
    model_name='llama3.1:8b', 
    provider=OllamaProvider(base_url='http://localhost:11434/v1'),
)


triage_agent = Agent(
    ollama_model, # or simply openai:gpt-4o
    deps_type=TriageDependencies,
    output_type=TriageOutput,
    system_prompt=(
        "You are a triage assistant helping patients. "
        "Provide clear advice and assess urgency."
    ),
)

# Static system prompts: These are known when writing the code and can be defined via the system_prompt parameter of the Agent constructor.
# Dynamic system prompts: These depend in some way on context that isn't known until runtime, and should be defined via functions decorated with @agent.system_prompt.
@triage_agent.system_prompt
async def add_patient_name(ctx: RunContext[TriageDependencies]) -> str:
    patient_name = await ctx.deps.db.patient_name(id=ctx.deps.patient_id)
    return f"The patient's name is {patient_name!r}."


# Defines a tool the agent can call.
# Lets the agent fetch vitals dynamically if needed.
@triage_agent.tool
async def latest_vitals(ctx: RunContext[TriageDependencies]) -> dict[str, Any]:
    """Returns the patient's latest vital signs."""
    return await ctx.deps.db.latest_vitals(id=ctx.deps.patient_id)


async def main() -> None:
    deps = TriageDependencies(patient_id=43, db=DatabaseConn())

    result = await triage_agent.run(
        "I have chest pain and trouble breathing.",
        deps=deps,
    )
    print(result.output)
    """
    Example output:
    response_text='Your symptoms are serious. Please call emergency services immediately. A nurse will contact you shortly.'
    escalate=True
    urgency=10
    """

    result = await triage_agent.run(
        "I have a mild headache since yesterday.",
        deps=deps,
    )
    print(result.output)
    """
    Example output:
    response_text='It sounds like your headache is not severe, but monitor it closely. If it worsens or you develop new symptoms, contact your doctor.'
    escalate=False
    urgency=3
    """


if __name__ == "__main__":
    asyncio.run(main())
```

