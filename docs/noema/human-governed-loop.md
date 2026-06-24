# Noema Human-Governed Development Loop

**Status:** Active  
**Date:** 2026-06-24  
**Scope:** All Noema repos

---

## Overview

Noema Architecture development follows a single-task, human-gated loop:

```
1 task = 1 GitHub Issue = 1 branch = 1 PR
```

Every piece of work is proposed, scoped, assigned, executed, reviewed, and merged through this loop. No work enters a repo without a matching Issue and PR.

---

## Repos

| Repo | Purpose |
|------|---------|
| `rag-fish/NoesisNoema` | iOS app |
| `rag-fish/noesisnoema-pipeline` | Embedding & ingestion pipeline |
| `rag-fish/noema-agent` | Agent orchestration layer |
| `rag-fish/RAGfish` | Architecture docs, ADRs, contracts |

---

## Actors

| Actor | Role |
|-------|------|
| **Max / ChatGPT** | Architect, reviewer, prompt designer |
| **Claude CLI** | Audit, architecture docs, broad investigation |
| **Codex CLI** | Focused implementation, tests, small patches |
| **Taka** | Final reviewer and merge approver |

---

## Task Lifecycle

```
proposed → ready → in progress → in review → merged
                                           ↘ blocked
```

| Status | Meaning |
|--------|---------|
| `proposed` | Idea captured; not yet scoped or assigned |
| `ready` | Scoped, branched, assigned to an owner agent |
| `in progress` | Owner agent is actively working |
| `in review` | PR open; awaiting Taka's review |
| `merged` | PR merged to main by Taka |
| `blocked` | Work halted; waiting on a dependency or decision |

Transitions are managed via GitHub Project field updates (see [CLI automation](#cli-automation) below).

---

## Required Task Fields

Every GitHub Issue must include these fields before it moves to `ready`:

| Field | Description |
|-------|-------------|
| `title` | One-line imperative statement of the work |
| `target repo` | One of the four Noema repos |
| `task type` | `audit` / `docs` / `feature` / `fix` / `test` / `infra` |
| `owner agent` | `claude` / `codex` / `taka` / `max` |
| `branch name` | Per naming convention below |
| `Definition of Done` | Explicit, verifiable exit criteria |
| `validation commands` | Shell commands that confirm DoD is met |
| `linked PR` | Added once PR is opened |
| `merge owner` | Always `taka` unless explicitly delegated |

---

## Branch Naming Convention

```
<type>/<short-name>
```

| Type | When to use |
|------|------------|
| `audit/` | Code or architecture investigation, no changes |
| `docs/` | Documentation, ADRs, contracts |
| `feature/` | New capability |
| `fix/` | Bug fix or regression |
| `test/` | Test-only changes |
| `infra/` | CI, scripts, project config |

**Rules:**
- Lowercase, hyphen-separated words only
- Short: 2–5 words
- No ticket numbers in the branch name (the Issue link carries that)

**Examples:**
```
audit/retrieval-bypass-investigation
docs/noema-human-governed-loop
feature/ragpack-streaming-export
fix/vectorstore-populate-on-launch
test/embedding-pipeline-unit-coverage
infra/ci-github-actions-setup
```

---

## Issue Body Template

Use this template for every new GitHub Issue:

```markdown
## Objective
<!-- One paragraph: what are we trying to achieve and why now? -->

## Target Repo
<!-- rag-fish/NoesisNoema | rag-fish/noesisnoema-pipeline | rag-fish/noema-agent | rag-fish/RAGfish -->

## Scope
<!-- Bullet list of what IS included in this task -->

## Out of Scope
<!-- Bullet list of what is explicitly excluded -->

## Branch
<!-- e.g. feature/ragpack-streaming-export -->

## Owner Agent
<!-- claude | codex | taka | max -->

## Definition of Done
<!-- Explicit, verifiable exit criteria — each item should be checkable -->
- [ ] ...
- [ ] ...

## Validation
<!-- Shell commands or manual steps that confirm DoD is met -->
```sh
# example
swift test --filter EmbeddingTests
```

## Review / Merge Rule
<!-- Default: Taka reviews and merges. Override only if explicitly agreed. -->
- Reviewer: Taka
- Merge owner: Taka
- Merge strategy: squash
```

---

## PR Body Template

Use this template for every pull request:

```markdown
## Linked Issue
Closes #<issue-number>

## Summary
<!-- 2–4 sentences: what changed and why -->

## Changes
<!-- Concise bullet list of files/components touched -->
- 

## Out of Scope
<!-- What was deliberately left out of this PR -->
- 

## Validation
<!-- Commands run to verify the change -->
```sh

```

## Risks
<!-- Known risks, edge cases, or follow-up concerns -->
- 

## Next Task
<!-- Issue number or title of the logical next step, if any -->
#<next-issue> or N/A
```

---

## CLI Automation

All task creation flows through `gh` (GitHub CLI). GraphQL is used only for GitHub Project field updates where the REST API is insufficient.

### Full task-creation sequence

```sh
# 1. Create the Issue
gh issue create \
  --repo <owner>/<repo> \
  --title "<title>" \
  --body-file /tmp/issue-body.md \
  --label "<task-type>"

# 2. Add the Issue to the GitHub Project
gh project item-add <project-number> \
  --owner rag-fish \
  --url <issue-url>

# 3. Set the Status field (requires item ID from step 2)
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "<PROJECT_ID>"
      itemId: "<ITEM_ID>"
      fieldId: "<STATUS_FIELD_ID>"
      value: { singleSelectOptionId: "<READY_OPTION_ID>" }
    }) { projectV2Item { id } }
  }'

# 4. Open PR (after branch work is done)
gh pr create \
  --repo <owner>/<repo> \
  --title "<PR title>" \
  --body-file /tmp/pr-body.md \
  --base main \
  --head <branch-name>
```

> **Note:** `PROJECT_ID`, `STATUS_FIELD_ID`, and option IDs are project-specific. Run `gh project field-list <project-number> --owner rag-fish --format json` to discover them. These values must be confirmed before automation is wired up — see [open questions](#open-questions) below.

### Scaffold script

A non-destructive dry-run script is available at `scripts/noema-task-create.sh`. It prints the `gh` commands it would run without executing them. Pass `--execute` to run for real.

---

## Open Questions

These fields need manual confirmation before the CLI automation can be fully wired:

| Item | What's needed |
|------|--------------|
| GitHub Project number | The numeric ID of the Noema project board |
| `PROJECT_ID` | GraphQL node ID — run `gh project list --owner rag-fish` |
| `STATUS_FIELD_ID` | Field node ID for the "Status" column |
| Status option IDs | Node IDs for each status value (`proposed`, `ready`, etc.) |
| Label names | Confirm labels exist in each repo (`audit`, `docs`, `feature`, `fix`, `test`, `infra`) |

---

## Related Docs

- [ADR-0000: Product Constitution](../adr/adr-0000-product-constitution.md)
- [ADR-0011: Retrieval Quality Recovery](../adr/ADR-0011-update-retrieval-quality-and-context-budget.md)
- [Architecture Overview](../architect/ARCHITECTURE.md)
