#!/usr/bin/env bash
#
# create-labels.sh — create just the Dropzona roadmap labels.
#
# A convenience subset of setup-github.sh for when you only want the label
# taxonomy in place (e.g. bootstrapping an existing repo, or re-syncing colors
# after an edit to .github/roadmap-data.json). Idempotent: `gh label create
# --force` updates color/description if the label already exists.
#
# Requirements: gh, jq. Auth scope: repo.
#
# Usage:
#   REPO=aalex0372/roadmap ./scripts/create-labels.sh
#   ./scripts/create-labels.sh          # defaults REPO to aalex0372/roadmap
#
set -euo pipefail

REPO="${REPO:-aalex0372/roadmap}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="${DATA_FILE:-$SCRIPT_DIR/../.github/roadmap-data.json}"

command -v gh >/dev/null 2>&1 || { echo "gh not installed — https://cli.github.com" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not installed — https://jqlang.github.io/jq" >&2; exit 1; }
[[ -f "$DATA_FILE" ]] || { echo "data file not found: $DATA_FILE" >&2; exit 1; }
jq empty "$DATA_FILE" 2>/dev/null || { echo "invalid JSON: $DATA_FILE" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "not logged in — run: gh auth login" >&2; exit 1; }
gh repo view "$REPO" >/dev/null 2>&1 || { echo "cannot access repo '$REPO'" >&2; exit 1; }

echo "==> Creating labels on $REPO"
count=0
while read -r label; do
  name=$(jq -r '.name'        <<<"$label")
  color=$(jq -r '.color'      <<<"$label")
  desc=$(jq -r '.description' <<<"$label")
  if gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null 2>&1; then
    echo "  ok  $name"
    count=$((count + 1))
  else
    echo "  !!  $name failed" >&2
  fi
done < <(jq -c '.labels[]' "$DATA_FILE")

echo "==> Done. $count labels ensured on $REPO."
