---
weight: 1
title: NL2SQL Part 1.
date: 2025-09-06
draft: true
author: Han
description: A tutorial for Pydantic-AI
tags: ["NL2SQL", "Agent", "AI", "LLM", "SQL"]
categories: ["NL2SQL", "AI", "LLM", "SQL"]
---

## 💡Natural Language to SQL (NL2SQL) in the LLM Era

Data has become one of the most valuable resources of our time. Companies in finance, healthcare, logistics, retail, and many other fields collect enormous amounts of information every day. Much of this information is stored in relational databases, which are typically accessed using SQL.

While SQL provides the raw outputs of a query, the critical step lies in interpreting these results. Developing intuition from retrieved data is essential for identifying meaningful patterns, uncovering relationships, and supporting evidence-based decision-making.

This is where **Natural Language to SQL (NL2SQL)** becomes valuable. Instead of writing SQL code, users can simply ask a question in plain language, such as:

<p align="center"><i>“What are the top five products sold in Asia this year?”</i></p>  

and automatically receive the result—without having to construct a query like:

```sql
SELECT product, SUM(sales)
FROM transactions
WHERE region = 'Asia'
  AND date >= '2024-01-01'
GROUP BY product
ORDER BY SUM(sales) DESC
LIMIT 5;
```

The motivation is clear: **make structured data accessible to everyone**. In practice, this means:

* Reducing dependency on technical expertise.
* Enabling deeper understanding of data.
* Supporting more efficient research and analysis.

However, achieving this vision introduces significant technical challenges.


## The Challenges of NL2SQL

Developing systems that can reliably translate natural language into SQL queries is a long-standing research challenge that sits at the intersection of natural language processing, information retrieval, and database management. **The difficulty lies not only in the inherent ambiguity and variability of human language, but also in the structural complexity and heterogeneity of real-world databases**. While the vision of democratizing access to data through natural language interfaces is compelling, realizing it in practice requires addressing several deep challenges—ranging from robust language understanding and schema alignment, to handling noisy data, adapting to diverse SQL dialects, and ensuring secure and efficient deployment.

Beyond these technical hurdles, **organizational culture plays a decisive role**. In many enterprises, data access is still mediated by technical gatekeepers, and decision-making cultures are shaped by long-standing workflows and hierarchies. For NL2SQL systems to be truly effective, companies must embrace a culture of data accessibility—empowering non-technical users, fostering trust in automated systems, and promoting responsible use of sensitive information. Without this cultural shift, even the most advanced systems risk being underutilized or confined to experimental settings.

The next sections will explore the key challenges that stand in the way of realizing NL2SQL at scale.

<!-- ### 1. Ambiguity in Natural Language -->

<!-- Human language is inherently imprecise, and resolving its ambiguity is one of the most difficult aspects of NL2SQL. -->

<!-- * **Lexical ambiguity** -->
<!--   Words often have multiple meanings. For example: -->
<!--   *Query*: *“Show me all accounts at the bank.”* -->
<!--   *Interpretation A*: financial institution (table `bank_accounts`) -->
<!--   *Interpretation B*: riverbank survey data (table `riverbank_records`) -->
<!--   A robust NL2SQL system must disambiguate based on schema context or user intent. -->

<!-- * **Syntactic ambiguity** -->
<!--   The same sentence structure can be parsed in more than one valid way. -->
<!--   *Query*: *“List employees in sales with high performance reviews.”* -->

<!--   * Interpretation A: employees who are in the sales department **and** have high reviews. -->
<!--   * Interpretation B: sales records that have been associated with high-performing employees. -->
<!--     Resolving this requires both syntactic parsing and semantic grounding in the database schema. -->

<!-- * **Underspecification** -->
<!--   Many natural queries leave out critical details. -->
<!--   *Query*: *“How many users are in England?”* -->

<!--   * Which dataset? (e.g., active users, registered users, trial users) -->
<!--   * Which time frame? (e.g., this month, this year, all-time) -->
<!--   * Which region definition? (e.g., England vs. UK vs. Great Britain) -->
<!--     Possible mitigation: asking clarification questions, or leveraging metadata such as default filters. -->

<!-- * **Semantic mismatch** -->
<!--   Sometimes, the user’s request cannot be expressed in terms of the schema. -->
<!--   *Query*: *“How many singers died of COVID in 2021?”* -->
<!--   If the database only contains discography and release dates, the answer is impossible. -->
<!--   Systems must detect such gaps and respond gracefully (e.g., “This information is not available in the current database”). -->

<!-- --- -->

<!-- ### 2. Complexity of Real-World Databases -->

<!-- Academic benchmarks often rely on small, well-structured schemas. In contrast, enterprise databases are large, noisy, and domain-specific. -->

<!-- * **Scale** -->
<!--   Real systems may contain hundreds of tables and thousands of columns. For instance, a healthcare database might have tables for patients, visits, diagnoses, prescriptions, lab results, and billing records. Querying requires reasoning across long chains of joins. -->

<!-- * **Schema opacity** -->
<!--   Column names are often cryptic. -->
<!--   Example: `amt_rec` (amount received), `c_id` (customer ID), `dx_code` (diagnosis code). -->
<!--   Such names may be clear to developers but obscure to models. Schema linking techniques, such as embedding-based matching or using documentation, are needed to align natural words to column names. -->

<!-- * **Domain-specific conventions** -->
<!--   Each industry encodes knowledge differently. -->

<!--   * Finance: abbreviations like P\&L, EBITDA. -->
<!--   * Healthcare: ICD-10 codes for diseases. -->
<!--   * Logistics: hub-and-spoke identifiers. -->
<!--     Models must adapt to specialized vocabularies and structures. -->

<!-- * **Data noise and inconsistency** -->
<!--   Industrial data often contains duplicates, missing values, or legacy artifacts. -->
<!--   Example: customer names appearing as *“John Doe,” “J. Doe,” “Doe, John”*. -->
<!--   An NL2SQL system may miscount unless it can account for such inconsistencies. -->

<!-- --- -->

<!-- ### 3. Barriers to Practical Deployment -->

<!-- Even when an NL2SQL model generates correct SQL, real-world deployment introduces operational and governance concerns. -->

<!-- * **Heterogeneity of SQL dialects** -->
<!--   SQL differs across engines. -->

<!--   * PostgreSQL: `ILIKE` for case-insensitive search. -->
<!--   * MySQL: `LOWER()` + `LIKE` combination. -->
<!--   * Oracle: `ROWNUM` vs. `LIMIT`. -->
<!--     A system must either normalize queries or adapt dynamically to the target dialect. -->

<!-- * **Generalization gap** -->
<!--   Models trained on benchmarks (e.g., Spider, WikiSQL) often achieve high accuracy but struggle on industrial databases. -->

<!--   * Academic DB: 10 tables, clean schema, descriptive names. -->
<!--   * Real DB: 500 tables, cryptic abbreviations, evolving schema. -->
<!--     Closing this gap requires domain adaptation and continual learning. -->

<!-- * **Dependence on external knowledge** -->
<!--   Some queries cannot be answered from schema alone. -->
<!--   *Query*: *“Show me Q4 revenue excluding one-time adjustments.”* -->
<!--   Here, the concept of “adjustments” may only be defined in business documentation or policy manuals. Integrating external knowledge sources (ontologies, business rules) becomes essential. -->

<!-- * **Security and governance** -->
<!--   Allowing natural language access to sensitive databases introduces risks: -->

<!--   * Malicious injection: a user typing *“Drop all tables”* disguised as a natural query. -->
<!--   * Data leakage: exposing private information inadvertently. -->
<!--     Mitigation requires safeguards such as query sanitization, access control, and audit logging. -->

<!-- --- -->

<!-- ✅ This framing not only **states the problems** but also **illustrates them with concrete examples** and hints at **possible strategies** (schema linking, clarification, dialect normalization, query sanitization). -->

<!-- Would you like me to add a **“Research Directions / Mitigation Strategies”** subsection after each challenge (e.g., methods like semantic parsing, ontology grounding, query repair), so the section reads more like a roadmap? -->

<!-- ## ⚙️ Approaches in the LLM Era -->

<!-- The rise of **Large Language Models (LLMs)** has given NL2SQL a major boost. Instead of building models from scratch, researchers now adapt powerful general-purpose models (GPT, Llama, T5, etc.) to SQL generation. -->

<!-- ### 🔹 In-Context Learning (ICL) -->

<!-- In ICL, we use **prompt engineering** to guide LLMs at inference time without retraining. -->

<!-- **Example prompt:** -->

<!-- ``` -->
<!-- You are a SQL expert. -->  
<!-- Given the following table schema and a natural language question, -->  
<!-- generate a syntactically correct SQL query. -->  

<!-- Table: Customers (CName, Age, City) -->  
<!-- Question: How many customers are older than 30? -->  
<!-- Answer: SELECT COUNT(*) FROM Customers WHERE Age > 30; -->
<!-- ``` -->

<!-- * **Advantages**: No training required, flexible, dynamic. -->
<!-- * **Disadvantages**: -->

<!--   * Limited by context window size (large schemas can’t fit). -->
<!--   * Performance depends heavily on how examples are chosen. -->

<!-- 👉 Researchers experiment with **example selection strategies**: random sampling, similarity-based retrieval, masking sensitive tokens, and **self-correction loops** where the LLM critiques and revises its own SQL. -->

<!-- --- -->

<!-- ### 🔹 Fine-Tuning -->

<!-- Another approach is to train or fine-tune models on **NL-SQL pairs**. -->

<!-- * **Advantages**: More robust, domain-adapted, higher accuracy. -->
<!-- * **Disadvantages**: Expensive, requires large high-quality datasets, and the model becomes static (can’t adapt to new schemas without retraining). -->

<!-- Fine-tuning works best in stable domains — e.g., a financial institution repeatedly querying the same data warehouse. -->

<!-- --- -->

<!-- ### 🔹 Self-Correction and Agents -->

<!-- A promising direction is treating NL2SQL as a **multi-step reasoning task** rather than a single shot. -->

<!-- * **Self-correction**: The model drafts an initial SQL, then refines it by decomposing the task. -->
<!-- * **Agentic frameworks**: LLMs act as agents that query schema metadata, clarify vague user intent, or iteratively improve SQL through feedback. -->

<!-- For example, a user might ask: -->
<!-- *“What is the most common component in the warehouse?”* -->
<!-- Instead of hallucinating, the system could **ask clarifying questions**: -->

<!-- 1. Which warehouse? -->
<!-- 2. Which component category? -->

<!-- This guided interaction dramatically improves SQL quality. -->

<!-- --- -->
<!-- ## 📊 Benchmarking Datasets & Performance -->

<!-- | Dataset                            | Scale & Domain                                      | Example Characteristics                          | Reported LLM Performance                                        | -->
<!-- | ---------------------------------- | --------------------------------------------------- | ------------------------------------------------ | --------------------------------------------------------------- | -->
<!-- | **WikiSQL**                        | 80k queries, 24k tables (Wikipedia)                 | Single-table queries, relatively simple schemas  | Widely solved (>90% accuracy by many models)                    | -->
<!-- | **Spider v1.0**                    | 200 DBs, 138 domains, \~10k queries                 | Cross-domain, multi-table joins                  | GPT-O1 preview: **91.2%** <br> GPT-4: \~55%                     | -->
<!-- | **BIRD**                           | 13k pairs, 95 DBs, 37 domains                       | Includes DB descriptions, efficiency metric      | GPT-O1 preview: **73.0%** <br> GPT-4: 54.89% <br> Human: 92.96% | -->
<!-- | **Spider v2.0**                    | Industrial DBs: 632 queries, avg. 812 columns/DB    | Long queries (>100 lines), industrial complexity | GPT-O1 preview: **17.0%** <br> Llama-3.1-405B: **2.21%**        | -->
<!-- | **KaggleDBQA**                     | 272 queries, 8 DBs                                  | Annotator-built queries + docs                   | Smaller scale, niche use                                        | -->
<!-- | **Korean NL2SQL (AI-Hub, Archer)** | AI-Hub: 6k pairs <br> Archer: 1,042 queries, 20 DBs | Natural language questions in Korean             | Still underexplored                                             | -->

<!-- --- -->

<!-- This table highlights the **performance gap**: -->

<!-- * Models look strong on **Spider v1.0** (academic) but collapse on **Spider v2.0** (industrial). -->
<!-- * Datasets like **BIRD** introduce new evaluation metrics (efficiency, not just correctness). -->
<!-- * Language diversity (Korean NL2SQL) is still in early stages. -->


<!-- ## 📉 Typical Failures of LLM-based NL2SQL -->

<!-- Even strong models exhibit consistent failure modes: -->

<!-- * **Hallucination**: Inventing non-existent columns or tables. -->
<!-- * **Schema mismatch**: Misunderstanding abbreviations or cryptic names. -->
<!-- * **Contextual errors**: Ignoring temporal context or business-specific rules. -->
<!-- * **Performance degradation**: Especially severe when moving from Spider v1.0 to Spider v2.0. -->

<!-- --- -->

<!-- ## 🔮 The Road Ahead -->

<!-- Where are we today? -->

<!-- * LLMs are good at **academic benchmarks** but **struggle in enterprise environments**. -->
<!-- * Schema size, ambiguity, and domain-specific quirks make deployment challenging. -->
<!-- * Real progress requires **patient, long-term investment**. -->

<!-- ### Promising directions: -->

<!-- 1. **Schema-aware prompting** – selectively retrieving only the relevant schema pieces instead of dumping the entire DB schema into the prompt. -->
<!-- 2. **Guided UIs** – involve users in query refinement (presenting options for warehouses, dates, categories). -->
<!-- 3. **Hybrid systems** – combining symbolic reasoning with neural generation. -->
<!-- 4. **LLM agents** – breaking down the task into steps: schema linking → SQL generation → validation → execution. -->
<!-- 5. **Robust evaluation** – datasets like Spider v2.0 and BIRD push models closer to real-world conditions. -->

<!-- --- -->

<!-- ## ✨ Conclusion -->

<!-- NL2SQL embodies a simple idea with transformative potential: letting people ask questions in natural language and get answers from structured data. -->

<!-- But behind that simplicity lies a web of challenges — linguistic ambiguity, messy schemas, deployment hurdles. LLMs have injected new energy into this field, but their performance drops sharply outside academic benchmarks. -->

<!-- The way forward isn’t just bigger models. It’s **better prompts, smarter agents, guided interfaces, and schema-aware techniques** — all built with realistic expectations. -->

<!-- As the field matures, NL2SQL could truly democratize access to data, empowering anyone — not just SQL experts — to unlock insights from the world’s most valuable resource: information. -->

<!-- --- -->

<!-- Would you like me to **polish this into a professional blog post format with visuals in mind** (like code blocks, dataset comparison tables, diagrams you can later add), or keep it as a **technical long-form article** that reads like a survey paper summary? -->

<!-- # Lessons Learned -->

<!-- # References -->
<!-- - --> 
