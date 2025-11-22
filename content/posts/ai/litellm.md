---
weight: 1
title: "LiteLLM: LLM Proxy Server"
date: 2025-09-18
draft: false
hiddenFromHomePage: true
author: Han
description: "A tutorial for llm proxy server and litellm"
tags: ["LLM Proxy server", "LiteLLM", "AI", "LLM"]
categories: ["LLM Proxy server", "LiteLLM", "LLM"]
---

## Why an LLM proxy at all?

An LLM proxy sits between your app and model providers (OpenAI, Anthropic, Google, Ollama, etc.). It gives you a unified API (usually OpenAI-compatible), centralized auth, usage controls (budgets / rate-limits), routing and fallbacks, and caching—without changing your application code for each vendor.

<!-- There is a trade-off: adding a proxy introduces another moving piece (and potential single point of failure). For pure observability When you do want a proxy, Langfuse recommends LiteLLM, which is open source, self-hostable, and has first-class integration with Langfuse. -->

## What is LiteLLM?

LiteLLM is an OpenAI-compatible LLM Gateway that lets you call 100+ providers behind one API, plus adds budgets/rate-limits, model access control, caching, routing, admin UI, and more. You can run it as a single Docker container with a YAML config. 

An LLM Proxy is a service that sits between your application and the LLM provider's API.

