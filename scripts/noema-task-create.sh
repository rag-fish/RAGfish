#!/usr/bin/env bash
# noema-task-create.sh
# Scaffold a Noema task: GitHub Issue → Project → PR template
#
# Usage:
#   ./scripts/noema-task-create.sh [options]
#
# Options:
#   --repo         Target repo, e.g. rag-fish/NoesisNoema (required)
#   --title        Issue title (required)
#   --branch       Branch name, e.g. feature/my-thing (required)
#   --type         Task type: audit | docs | feature | fix | test | infra (required)
#   --agent        Owner agent: claude | codex | taka | max (required)
#   --project      GitHub Project number (optional, for item-add)
#   --execute      Actually run the commands (default: dry-run)
#   --help         Show this help
#
# Secrets: relies on GITHUB_TOKEN in the environment (set by gh auth login).
#          Never hardcode tokens here.
#
# Example (dry-run):
#   ./scripts/noema-task-create.sh \
#     --repo rag-fish/RAGfish \
#     --title "Docs: define Noema human-governed loop" \
#     --branch docs/noema-human-governed-loop \
#     --type docs \
#     --agent claude
#
# Example (execute):
#   ./scripts/noema-task-create.sh ... --execute

set -euo pipefail

# ── defaults ────────────────────────────────────────────────────────────────
REPO=""
TITLE=""
BRANCH=""
TYPE=""
AGENT=""
PROJECT=""
DRY_RUN=true

# ── colours ─────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
dryrun()  { echo -e "${YELLOW}[dry-run]${RESET} $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }

# ── usage ────────────────────────────────────────────────────────────────────
usage() {
  sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
  exit 0
}

# ── arg parsing ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)     REPO="$2";    shift 2 ;;
    --title)    TITLE="$2";   shift 2 ;;
    --branch)   BRANCH="$2";  shift 2 ;;
    --type)     TYPE="$2";    shift 2 ;;
    --agent)    AGENT="$2";   shift 2 ;;
    --project)  PROJECT="$2"; shift 2 ;;
    --execute)  DRY_RUN=false; shift ;;
    --help|-h)  usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# ── validation ───────────────────────────────────────────────────────────────
errors=()
[[ -z "$REPO" ]]   && errors+=("--repo is required")
[[ -z "$TITLE" ]]  && errors+=("--title is required")
[[ -z "$BRANCH" ]] && errors+=("--branch is required")
[[ -z "$TYPE" ]]   && errors+=("--type is required")
[[ -z "$AGENT" ]]  && errors+=("--agent is required")

valid_types="audit docs feature fix test infra"
valid_agents="claude codex taka max"

if [[ -n "$TYPE" ]] && ! echo "$valid_types" | grep -qw "$TYPE"; then
  errors+=("--type must be one of: $valid_types")
fi
if [[ -n "$AGENT" ]] && ! echo "$valid_agents" | grep -qw "$AGENT"; then
  errors+=("--agent must be one of: $valid_agents")
fi
if [[ -n "$BRANCH" ]] && ! echo "$BRANCH" | grep -qE "^(audit|docs|feature|fix|test|infra)/.+"; then
  errors+=("--branch must match <type>/<short-name>, e.g. feature/my-thing")
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  echo "Errors:"
  for e in "${errors[@]}"; do echo "  - $e"; done
  echo ""
  usage
fi

# ── build issue body ──────────────────────────────────────────────────────────
ISSUE_BODY=$(cat <<ISSUE_BODY_EOF
## Objective
<!-- One paragraph: what are we trying to achieve and why now? -->

## Target Repo
${REPO}

## Scope
<!-- Bullet list of what IS included in this task -->
-

## Out of Scope
<!-- Bullet list of what is explicitly excluded -->
-

## Branch
\`${BRANCH}\`

## Owner Agent
${AGENT}

## Definition of Done
- [ ]

## Validation
\`\`\`sh
# add validation commands here
\`\`\`

## Review / Merge Rule
- Reviewer: Taka
- Merge owner: Taka
- Merge strategy: squash
ISSUE_BODY_EOF
)

ISSUE_BODY_FILE="/tmp/noema-issue-body-$$.md"

# ── build PR body ─────────────────────────────────────────────────────────────
PR_BODY=$(cat <<PR_BODY_EOF
## Linked Issue
Closes #<issue-number>

## Summary
<!-- 2–4 sentences: what changed and why -->

## Changes
-

## Out of Scope
-

## Validation
\`\`\`sh

\`\`\`

## Risks
-

## Next Task
N/A
PR_BODY_EOF
)

PR_BODY_FILE="/tmp/noema-pr-body-$$.md"

# ── run or print ──────────────────────────────────────────────────────────────
run_or_print() {
  local label="$1"; shift
  if $DRY_RUN; then
    dryrun "$label"
    echo "  $(echo "$@" | sed 's/  */ /g')"
    echo ""
  else
    info "Running: $label"
    "$@"
    ok "Done: $label"
  fi
}

echo ""
info "Noema task scaffold"
info "  repo:   $REPO"
info "  title:  $TITLE"
info "  branch: $BRANCH"
info "  type:   $TYPE"
info "  agent:  $AGENT"
$DRY_RUN && echo -e "${YELLOW}[dry-run mode — pass --execute to run for real]${RESET}"
echo ""

# Write temp files (always, so body is visible in dry-run too)
echo "$ISSUE_BODY" > "$ISSUE_BODY_FILE"
echo "$PR_BODY"    > "$PR_BODY_FILE"

if $DRY_RUN; then
  info "Issue body written to: $ISSUE_BODY_FILE"
  info "PR body template written to: $PR_BODY_FILE"
  echo ""
fi

# Step 1: create issue
run_or_print "gh issue create" \
  gh issue create \
    --repo "$REPO" \
    --title "$TITLE" \
    --body-file "$ISSUE_BODY_FILE" \
    --label "$TYPE"

# Step 2: add to project (only if --project supplied)
if [[ -n "$PROJECT" ]]; then
  OWNER="${REPO%%/*}"
  run_or_print "gh project item-add" \
    gh project item-add "$PROJECT" \
      --owner "$OWNER" \
      --url "https://github.com/${REPO}/issues/<issue-number>"

  dryrun "gh api graphql  (set Status=ready — requires PROJECT_ID and field IDs)"
  echo "  Run: gh project field-list $PROJECT --owner $OWNER --format json"
  echo "  to discover STATUS_FIELD_ID and option IDs, then wire up the mutation."
  echo ""
fi

# Step 3: PR reminder
run_or_print "gh pr create (after branch work is done)" \
  gh pr create \
    --repo "$REPO" \
    --title "$TITLE" \
    --body-file "$PR_BODY_FILE" \
    --base main \
    --head "$BRANCH"

if $DRY_RUN; then
  info "Review and edit the body files before running with --execute:"
  info "  Issue body: $ISSUE_BODY_FILE"
  info "  PR body:    $PR_BODY_FILE"
fi
