#!/usr/bin/env bash
#
# setup-github.sh — stand up the Dropzona roadmap on GitHub in one command.
#
# Reads .github/roadmap-data.json (the single source of truth) and creates:
#   1. Labels        (priority/effort/area/type/status) — idempotent
#   2. Milestones    (M0..M3) — idempotent via the REST API
#   3. Issues        (every DZ ticket) with labels + milestone
#   4. A Projects v2 board "Dropzona Roadmap" with single-select
#      Status / Priority / Effort fields, then adds each issue and
#      sets its field values.
#
# Re-runnable: labels/milestones are upserted; issues are matched by title
# so a second run does not create duplicates. The project is matched by name.
#
# Requirements: gh (>= 2.40), jq. Auth scopes: repo + project (read:project,
# project). If the project scope is missing the script skips the board step
# and prints exactly how to add it.
#
# Usage:
#   REPO=aalex0372/roadmap ./scripts/setup-github.sh
#   ./scripts/setup-github.sh            # defaults REPO to aalex0372/roadmap
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
REPO="${REPO:-aalex0372/roadmap}"
PROJECT_TITLE="${PROJECT_TITLE:-Dropzona Roadmap}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="${DATA_FILE:-$SCRIPT_DIR/../.github/roadmap-data.json}"

# ---------------------------------------------------------------------------
# Pretty output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'
  YLW=$'\033[33m'; BLU=$'\033[34m'; RST=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GRN=""; YLW=""; BLU=""; RST=""
fi
info()  { echo "${BLU}==>${RST} $*"; }
ok()    { echo "  ${GRN}ok${RST}  $*"; }
skip()  { echo "  ${DIM}--  $* (already exists)${RST}"; }
warn()  { echo "${YLW}!!${RST} $*" >&2; }
die()   { echo "${RED}xx${RST} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
info "Preflight checks"
command -v gh >/dev/null 2>&1 || die "gh (GitHub CLI) is not installed — https://cli.github.com"
command -v jq >/dev/null 2>&1 || die "jq is not installed — https://jqlang.github.io/jq"
[[ -f "$DATA_FILE" ]] || die "data file not found: $DATA_FILE"
jq empty "$DATA_FILE" 2>/dev/null || die "invalid JSON: $DATA_FILE"

if ! gh auth status >/dev/null 2>&1; then
  die "not logged in. Run: gh auth login"
fi
ok "gh authenticated"

# Confirm the repo is reachable (and thus that the token can write to it).
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  die "cannot access repo '$REPO'. Create it first (gh repo create $REPO --public) or fix REPO."
fi
ok "repo reachable: $REPO"

# Does the token carry a project scope? Projects v2 needs 'project'.
HAS_PROJECT_SCOPE=1
if ! gh auth status 2>&1 | grep -Eq '\bproject\b'; then
  HAS_PROJECT_SCOPE=0
  warn "the 'project' scope is not present on this token."
  warn "The board step will be skipped. To enable it:"
  warn "    gh auth refresh -s project,read:project"
fi

OWNER="${REPO%%/*}"

# ---------------------------------------------------------------------------
# 1. Labels
# ---------------------------------------------------------------------------
info "Creating labels"
jq -c '.labels[]' "$DATA_FILE" | while read -r label; do
  name=$(jq -r '.name'        <<<"$label")
  color=$(jq -r '.color'      <<<"$label")
  desc=$(jq -r '.description' <<<"$label")
  # --force makes create idempotent (updates color/description if it exists).
  if gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null 2>&1; then
    ok "label $name"
  else
    warn "label $name failed"
  fi
done

# ---------------------------------------------------------------------------
# 2. Milestones (REST — gh has no first-class milestone command)
# ---------------------------------------------------------------------------
info "Creating milestones"
# Cache existing milestones once (title -> number not needed here; we key issues
# by milestone *title* via the --milestone flag, which resolves server-side).
existing_ms=$(gh api --paginate "repos/$REPO/milestones?state=all" --jq '.[].title')
jq -c '.milestones[]' "$DATA_FILE" | while read -r ms; do
  title=$(jq -r '.title'       <<<"$ms")
  desc=$(jq -r '.description'  <<<"$ms")
  if grep -Fxq "$title" <<<"$existing_ms"; then
    skip "milestone $title"
  else
    gh api "repos/$REPO/milestones" -f title="$title" -f description="$desc" >/dev/null \
      && ok "milestone $title" \
      || warn "milestone $title failed"
  fi
done

# ---------------------------------------------------------------------------
# 3. Issues
# ---------------------------------------------------------------------------
info "Creating issues"
# Pull existing issue titles so a re-run is a no-op for already-created tickets.
existing_titles=$(gh issue list --repo "$REPO" --state all --limit 500 --json title --jq '.[].title')

# Collect the URLs of issues we know about (created now OR pre-existing) so the
# board step can add them. Written to a temp file because the jq pipe runs in a
# subshell.
URL_FILE="$(mktemp)"
trap 'rm -f "$URL_FILE"' EXIT

jq -c '.issues[]' "$DATA_FILE" | while read -r issue; do
  title=$(jq -r '.title'     <<<"$issue")
  body=$(jq -r '.body'       <<<"$issue")
  milestone=$(jq -r '.milestone' <<<"$issue")
  # Build repeated --label flags.
  label_args=()
  while IFS= read -r l; do label_args+=(--label "$l"); done < <(jq -r '.labels[]' <<<"$issue")

  if grep -Fxq "$title" <<<"$existing_titles"; then
    skip "issue $title"
    url=$(gh issue list --repo "$REPO" --state all --limit 500 \
            --search "$title" --json title,url \
            --jq ".[] | select(.title == \"$title\") | .url" | head -n1)
  else
    url=$(gh issue create --repo "$REPO" \
            --title "$title" \
            --body "$body" \
            --milestone "$milestone" \
            "${label_args[@]}")
    ok "issue $title"
  fi
  [[ -n "${url:-}" ]] && printf '%s\t%s\n' "$url" \
      "$(jq -r '[.status,.priority,.effort] | @tsv' <<<"$issue")" >>"$URL_FILE"
done

# ---------------------------------------------------------------------------
# 4. Projects v2 board
# ---------------------------------------------------------------------------
if [[ "$HAS_PROJECT_SCOPE" -eq 0 ]]; then
  warn "skipping the Projects v2 board (no 'project' scope)."
  warn "Add the scope and re-run to build the board: gh auth refresh -s project,read:project"
  info "Done (labels + milestones + issues created; board skipped)."
  exit 0
fi

info "Setting up the Projects v2 board: '$PROJECT_TITLE'"

# Find or create the project (owner-scoped).
PROJECT_NUMBER=$(gh project list --owner "$OWNER" --format json \
  --jq ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number" 2>/dev/null | head -n1 || true)

if [[ -z "${PROJECT_NUMBER:-}" ]]; then
  PROJECT_NUMBER=$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" \
    --format json --jq '.number')
  ok "created project #$PROJECT_NUMBER"
else
  skip "project #$PROJECT_NUMBER '$PROJECT_TITLE'"
fi

PROJECT_ID=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json --jq '.id')

# --- Ensure a single-select field exists with the given options ------------
# Usage: ensure_single_select "Status" "Now" "Next" "Later" "Parked" "Done"
ensure_single_select() {
  local field_name="$1"; shift
  local options=("$@")
  local existing
  existing=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
    --jq ".fields[] | select(.name == \"$field_name\") | .id" | head -n1 || true)
  if [[ -n "$existing" ]]; then
    skip "field '$field_name'"
    return 0
  fi
  local joined
  joined=$(IFS=,; echo "${options[*]}")
  gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
    --name "$field_name" \
    --data-type SINGLE_SELECT \
    --single-select-options "$joined" >/dev/null
  ok "field '$field_name' ($joined)"
}

# GitHub always seeds a default "Status" (Todo/In Progress/Done). We want our
# own columns; create Status only if our option set is absent, otherwise reuse.
ensure_single_select "Status"   "Now" "Next" "Later" "Parked" "Done"
ensure_single_select "Priority" "P0" "P1" "P2"
ensure_single_select "Effort"   "S" "M" "L"

# --- Resolve field + option ids into lookup maps ---------------------------
FIELDS_JSON=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json)

field_id()  { jq -r ".fields[] | select(.name==\"$1\") | .id"       <<<"$FIELDS_JSON"; }
option_id() { # field_name option_name
  jq -r ".fields[] | select(.name==\"$1\") | .options[] | select(.name==\"$2\") | .id" <<<"$FIELDS_JSON"
}

STATUS_FIELD_ID=$(field_id "Status")
PRIORITY_FIELD_ID=$(field_id "Priority")
EFFORT_FIELD_ID=$(field_id "Effort")

# --- Add each issue to the board and set its field values ------------------
info "Adding issues to the board and setting Status / Priority / Effort"
while IFS=$'\t' read -r url status priority effort; do
  [[ -z "$url" ]] && continue
  # add-item is idempotent-ish: it returns the item id whether new or existing.
  item_id=$(gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" \
    --format json --jq '.id' 2>/dev/null || true)
  if [[ -z "$item_id" ]]; then
    warn "could not add $url to the board"
    continue
  fi

  set_field() { # field_id option_name field_label
    local fid="$1" opt_name="$2" flabel="$3" oid
    oid=$(option_id "$flabel" "$opt_name")
    [[ -z "$oid" ]] && { warn "no option '$opt_name' on field '$flabel'"; return; }
    gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" \
      --field-id "$fid" --single-select-option-id "$oid" >/dev/null
  }

  set_field "$STATUS_FIELD_ID"   "$status"   "Status"
  set_field "$PRIORITY_FIELD_ID" "$priority" "Priority"
  set_field "$EFFORT_FIELD_ID"   "$effort"   "Effort"
  ok "board: ${url##*/}  [$status · $priority · $effort]"
done <"$URL_FILE"

info "Done."
echo
echo "${BOLD}Board:${RST}   https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
echo "${BOLD}Issues:${RST}  https://github.com/$REPO/issues"
echo "${BOLD}Tip:${RST}    open the board and add a 'Group by: Status' view for the Now/Next/Later/Parked/Done columns."
