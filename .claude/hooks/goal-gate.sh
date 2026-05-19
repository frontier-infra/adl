#!/usr/bin/env bash
# goal-gate.sh — Stop-hook gate for claude-layers /goal contracts.
#
# Blocks worker completion when CLAUDE_GOAL_ID points to a goal whose proof is
# missing or whose signed_off value is not the literal JSON boolean true.

set -euo pipefail

TASK_ID="${CLAUDE_GOAL_ID:-}"

if [ -z "$TASK_ID" ]; then
  echo '[goal-gate] no CLAUDE_GOAL_ID set; releasing (no contract to enforce).' >&2
  exit 0
fi

PROOF=".claude/goals/${TASK_ID}.proof.json"

if [ ! -f "$PROOF" ]; then
  echo "[goal-gate] BLOCK: no proof at $PROOF. Run /goal-verify $TASK_ID first." >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo '[goal-gate] BLOCK: jq is required to read the proof artifact.' >&2
  exit 2
fi

SIGNED="$(jq -r '.signed_off' "$PROOF")"

if [ "$SIGNED" = "true" ]; then
  echo "[goal-gate] RELEASE: $TASK_ID signed off." >&2
  exit 0
fi

REASON="$(jq -r '.kickback_reason // "unspecified"' "$PROOF")"
echo "[goal-gate] BLOCK: signed_off=$SIGNED; reason: $REASON" >&2
exit 2
