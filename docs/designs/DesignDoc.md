# Design Doc: RAGfish Unified RAGpack Architecture & Private QA History

## Author
- Human governance owner and architecture reviewer

## Status
- Implemented

## Background / Motivation
To build a truly private, user-owned LLM RAG ecosystem enabling seamless knowledge import, retrieval, and QA thread management, with no reliance on cloud providers. Current RAG tools were fragmented and lacked a standard, portable pack format and local history. We wanted RAG that feels like "your own AGI lab", not SaaS. (See GitHub discussions and ADR #0001.)  
Recently, powerful lightweight local models like Jan-v1-4B and Jan-v1-4V have arrived, expanding on-device capabilities including multimodal (image recognition) features, making full offline RAG even more compelling.

## Goals & Non-Goals
### Goals
- Unified RAGpack ZIP format for all knowledge artifacts
- Full offline/Apple Silicon RAG
- Threaded QA history and multi-pack support
- OSS-first, developer-friendly
- Extensible for future right-pane, p2p, mobile
- Seamless support for quantized GGUF models, with Colab-based downloads as an optional path
- macOS and iOS app feature parity for unified UX
- Multimodal (image/diagram/chart) interpretation integrated into RAG QA

### Non-Goals
- Not building cloud/SaaS solution
- Not supporting legacy per-file chunks/embeddings/tokenizer workflows

## Proposal / Solution Overview
The new architecture centers on the RAGpack (.zip) as single source of truth, integrating all embeddings, chunks, and metadata. Preprocessing is handled by noesisnoema-pipeline, consumption by NoesisNoema (macOS/iOS) app. All QA history/thread logic is managed client-side. UI is modern, 2-pane, extensible.  
The architecture now supports multimodal LLMs, enabling interpretation of images, diagrams, and charts within RAG QA. Pipeline updates allow optional cloud or local acquisition of gguf models, making Colab-based downloads optional rather than required. macOS and iOS builds share a common core to ensure seamless feature parity and unified user experience.  
Refer to assets/* for updated diagrams.

## Alternatives Considered
- Per-file artifact management (not portable/complex UX)  
- Cloud RAG/SaaS, but violates privacy/local-first philosophy

## Impact / Risk
- Much simpler onboarding, lower friction for new users  
- Improved privacy/security: nothing leaves device by default  
- Risk: some "power users" lose ultra-granular control (tradeoff for UX/maintainability)

## Implementation Plan
- Completed: UML/design/README/ARCHITECTURE/ADR sync, pipeline and app refactor, world-class UX, public repo launch  
- Next: Full integration of Jan-v1-4B/4V multimodal LLMs  
  Shared macOS/iOS codebase for feature parity  
  Enhanced pipeline with modular download/import of GGUF models  
  iOS app, right-pane upgrades, plugin API, multi-RAGpack analytics, more

## Open Questions
- What new uses or communities might emerge from open RAGpack standards?  
- How will decentralized RAG evolve with better local LLMs and device sync?  
- Any friction points for non-technical users?