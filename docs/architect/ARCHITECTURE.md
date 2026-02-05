# System Architecture: RAGfish

## Overview
RAGfish is a privacy-first, on-device Retrieval-Augmented Generation (RAG) engine for Apple platforms. The core system is designed to run fully locally, without cloud dependencies, and can be extended for both macOS and iOS.  
Visual architecture diagrams are available below and in `assets/`.

- ![Class Diagram](../assets/ClassDiagram.png)
- ![Sequence Diagram](../assets/SequenceDiagram.png)
- ![Use Case Diagram](../assets/UseCaseDiagram.png)
- ![Component Diagram](../assets/ComponentDiagram.png)

## Components

- **Core Engine**
  - Handles all LLM model inference, embedding, and retrieval logic.
  - Written for Apple Silicon (Metal/CoreML or native C/C++ backends).
  - Now supports the `jan-v1-4v` model with multi-modal (vision-text) capabilities, in addition to previous models.
  - The vision capability allows interpretation of images, illustrations, and data charts as part of the input.
  - GGUF-based inference is available as an option.
  - Example: Efficient vector search and prompt construction modules.
- **Document Manager**
  - Manages all user documents and RAGpacks; embeddings and chunks are now internal to the RAGpack ZIP, with explicit per-file management deprecated.
  - Supports preprocessed ZIP import (RAGpack format).
  - Example: Document chunking, embedding caching, and metadata indexing.
- **QA History/Thread Management**
  - Handles all question-answer pair tracking and session history.
  - Implemented in NoesisNoema app; see app and class diagrams for detail.
- **UI (Noesis)**
  - SwiftUI-based interface for chat, file management, settings.
  - Separated from business logic for platform flexibility.
  - Example: Responsive chat interface, document browser, and preferences panel.
- **File Import/Export**
  - Local file system and Google Drive integration.
  - Handles user data and model/resource import.
  - Only RAGpack ZIP (not loose embeddings/chunks) is now the supported format.
  - RAGpack creation can now be done via multiple pipelines, including updated Colab workflows and optional CLI-based GGUF preparation.
  - Example: ZIP unpacking, file format validation, and cloud sync hooks.

## Data Flow

- User launches RAGfish, which loads the `jan-v1-4v` model or other compatible GGUF/CoreML models; multi-modal queries are supported when using `jan-v1-4v`.
- User can import additional RAGpacks (preprocessed ZIPs from Colab or CLI); only RAGpack ZIP is supported, not per-file chunks or embeddings.
- User queries via chat; query is embedded and searched in the local vector store.
- Relevant chunks are retrieved; RAG pipeline combines prompt + context, sends to LLM for answer.
- Multi-RAGpack support and QA thread history is available in-app (NoesisNoema).
- All operations occur locally; no network/cloud access is required.
- Example: Query embedding → vector similarity search → prompt assembly → LLM inference → response display.

## Dependencies

- Apple Silicon (macOS/iOS, M1+)
- Swift (UI/business logic)
- C/C++/Metal/CoreML (backend performance)
- PlantUML or Mermaid (for architecture diagrams)
- Optional: Google Drive API (for import/export)
- Optional: `jan-v1-4v` model and GGUF runtime
- Optional: Hugging Face model download integration
- Example: CoreML for model acceleration, Swift concurrency for UI responsiveness.

## Extensibility

- Add support for new LLM/embedding models (GGUF, CoreML, etc)
- Future iOS-specific UX/UI enhancements
- Encrypted storage, biometric unlock, or multi-user support
- Serverless sharing of vector stores or models
- Plugin system for 3rd-party data connectors (TBD)
- Advanced UI for QA thread management, right-pane knowledge/trace preview (in NoesisNoema and future apps)
- Support for pluggable RAGpack sources and multi-format ingestion
- Support for future Jan family model updates and expanded multi-modal RAG workflows
- Example: Modular backend interfaces, pluggable import/export adapters, secure data layers.
- 
# Architecture Constitution: RAGfish (2026)

> This document is the **constitutional layer** of the RAGfish ecosystem.
>
> It defines *roles, boundaries, and invariants*.
> It does **not** describe implementation details, optimizations, or step‑by‑step workflows.
>
> Any design, code, or diagram in this repository must be interpretable through this document.

---

## 1. Purpose and Scope

RAGfish is a **local‑first RAG system design** intended to support long‑lived, privacy‑preserving, and human‑controlled knowledge work.

This repository documents:
- System‑level architectural intent
- Responsibility boundaries between components
- Assumptions about AI, humans, and computation

This repository explicitly does **not** define:
- UI/UX product decisions
- Feature roadmaps
- Model benchmarks
- Short‑term implementation tactics

Those belong to downstream applications (e.g. Noesis Noema) or execution layers.

---

## 2. Foundational Assumptions

### 2.1 On AI Systems

- LLMs are **stateless probabilistic executors**.
- LLMs do not learn from usage in a persistent or reliable manner.
- LLMs cannot be treated as responsible agents.

**Invariant**:
> AI systems assist reasoning but never own intent, memory, or responsibility.

### 2.2 On Humans

- Humans are the only accountable actors in the system.
- All long‑lived intent must remain human‑inspectable.

**Invariant**:
> Anything not verifiable by a human is considered untrusted.

---

## 3. Architectural Decomposition

The system is decomposed by **rate of change** and **responsibility**, not by technology.

### 3.1 Client Layer (e.g. Noesis Noema)

**Role**: Decision & Context Layer

Responsibilities:
- Human interaction and UX
- Context aggregation
- Policy definition (privacy, cost, latency)
- Routing decisions (where intelligence is invoked)
- Optional local RAG execution

Properties:
- Fast iteration
- Human‑adjacent
- Policy‑rich

**Invariant**:
> Routing decisions belong to the client, not the server.

---

### 3.2 Execution Layer (RAGfish Core / noema‑agent)

**Role**: Constrained Execution Layer

Responsibilities:
- Execute requests under given constraints
- Orchestrate LLM inference and tool usage
- Perform bounded agentic reasoning

Properties:
- On‑demand
- Replaceable
- Dockerized / service‑oriented

Explicit Non‑Responsibilities:
- Long‑term memory
- Policy decision‑making
- Autonomous goal setting

**Invariant**:
> The execution layer answers questions; it does not decide *which* questions to ask nor *how much* autonomy to take.

---

### 3.3 Knowledge Layer (RAGpack)

**Role**: Persistent Knowledge Assets

Characteristics:
- Model‑agnostic
- Structured for retrieval, not reasoning
- Shareable between client and server

Properties:
- Evolves independently from code
- Treated as data, not logic

**Invariant**:
> Knowledge must not encode behavior.

---

## 4. Separation by Evolution Speed

| Layer | Evolution Speed | Coupling Tolerance |
|-----|-----------------|-------------------|
| Client | Fast | Low |
| Execution | Medium | Very Low |
| Knowledge | Independent | Zero |

**Rule**:
> Components with different evolution speeds must never be tightly coupled.

---

## 5. Relationship to Existing Documentation

This document is **normative**.

Other materials are **descriptive**:
- `docs/adr/*` record historical decisions
- `docs/designs/*` capture exploratory or implementation‑level thinking
- `docs/assets/*`, `uml/`, `bpmn/` provide visualizations

If a conflict exists:
> **This document takes precedence.**

---

## 6. Diagrams

Architecture diagrams (Class / Component / Sequence / Use‑Case) are provided for illustration only.

They:
- Do not define responsibility boundaries
- Do not override architectural invariants

Refer to `docs/assets/` and `docs/uml/` for visuals.

---

## 7. Explicit Rejections

The following are intentionally rejected:

- Treating AI as a collaborator with memory
- Hidden or non‑inspectable decision logic
- Implicit coupling between model behavior and system design
- "Vibe coding" as a governing methodology

Exploration is allowed.
Permanence without structure is not.

---

## 8. Guiding Principle (Condensed)

> Humans decide.
> Artifacts remember.
> AI executes.

---

_End of Architecture Constitution_