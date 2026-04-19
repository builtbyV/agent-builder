#!/usr/bin/env bash
# invoke-agent.sh — universal entrypoint for agent-builder agents invoked by
# launchd, cron, Shortcuts, a webhook handler, or manually.
#
# Handles: .env loading, working-directory setup, per-agent lock files
# (prevent overlapping runs), log rotation (keeps the 20 most recent),
# and structured exit codes so schedulers can react sensibly.
#
# Usage:
#   invoke-agent.sh <agent.js> [agent args...]
#   invoke-agent.sh --cwd <dir> <agent.js> [agent args...]
#   invoke-agent.sh --log-dir <dir> <agent.js> [agent args...]
#
# Exit codes:
#   0    success
#   1    agent threw / returned non-zero
#   2    another run already in progress (lock held) — treat as transient, retry later
#   126  agent file not found
#   127  node not found in PATH
set -Eeuo pipefail

# Defaults: automation/ sits under the repo root by convention.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOCK_DIR="$SCRIPT_DIR/.locks"
KEEP_LOGS=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)     AGENT_DIR="$2"; shift 2 ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *) break ;;
  esac
done

[[ $# -ge 1 ]] || { echo "Usage: invoke-agent.sh <agent.js> [agent args...]" >&2; exit 2; }

AGENT="$1"; shift
AGENT_ARGS=("$@")

# Resolve agent path (absolute → use as-is; relative → resolve under AGENT_DIR)
if [[ "$AGENT" = /* ]]; then
  AGENT_PATH="$AGENT"
else
  AGENT_PATH="$AGENT_DIR/$AGENT"
fi

[[ -f "$AGENT_PATH" ]] || { echo "Agent not found: $AGENT_PATH" >&2; exit 126; }
command -v node >/dev/null 2>&1 || { echo "node not found in PATH" >&2; exit 127; }

# Load .env from the agent's directory if present, so ANTHROPIC_API_KEY etc. are in scope
# under launchd/cron (which start with minimal environment).
if [[ -f "$AGENT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$AGENT_DIR/.env"
  set +a
fi

mkdir -p "$LOG_DIR" "$LOCK_DIR"

AGENT_NAME="$(basename "$AGENT_PATH" .js)"
LOCK_PATH="$LOCK_DIR/$AGENT_NAME.lock"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/${AGENT_NAME}-${STAMP}.log"

# mkdir is atomic — safer than file-based flocks without the flock binary.
if ! mkdir "$LOCK_PATH" 2>/dev/null; then
  echo "[invoke-agent] $AGENT_NAME is already running (lock: $LOCK_PATH); skipping this tick." >&2
  exit 2
fi
trap 'rmdir "$LOCK_PATH" 2>/dev/null || true' EXIT

# Rotate old logs for this agent: keep the $KEEP_LOGS most recent.
if ls -1t "$LOG_DIR"/"${AGENT_NAME}"-*.log >/dev/null 2>&1; then
  ls -1t "$LOG_DIR"/"${AGENT_NAME}"-*.log | tail -n +$((KEEP_LOGS + 1)) | xargs -I{} rm -f {} 2>/dev/null || true
fi

cd "$AGENT_DIR"

echo "[invoke-agent] $(date -u +%Y-%m-%dT%H:%M:%SZ) agent=$AGENT_PATH args=[${AGENT_ARGS[*]:-}]" | tee "$LOG_FILE"

# Run and capture the real exit code through the tee pipeline.
set +e
node "$AGENT_PATH" "${AGENT_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"
STATUS=${PIPESTATUS[0]}
set -e

echo "[invoke-agent] $(date -u +%Y-%m-%dT%H:%M:%SZ) exit=$STATUS" | tee -a "$LOG_FILE"
exit "$STATUS"
