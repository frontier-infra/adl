#!/usr/bin/env bash
# claude-layers installer
# https://github.com/frontier-infra/claude-layers
#
# Installs the layered behavioral architecture into a Claude Code project.
# Safe to run multiple times. Asks before overwriting unless --yes is passed.

set -euo pipefail

VERSION="1.1.0"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Defaults
TARGET_DIR=""
MINIMAL=false
ASSUME_YES=false
SHOW_HELP=false

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal)
      MINIMAL=true
      shift
      ;;
    --yes|-y)
      ASSUME_YES=true
      shift
      ;;
    --help|-h)
      SHOW_HELP=true
      shift
      ;;
    --version|-v)
      echo "claude-layers installer v${VERSION}"
      exit 0
      ;;
    -*)
      echo "Unknown flag: $1"
      echo "Run with --help for usage."
      exit 1
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$1"
      else
        echo "Multiple target directories specified. Only one allowed."
        exit 1
      fi
      shift
      ;;
  esac
done

if [ "$SHOW_HELP" = true ]; then
  cat <<EOF
claude-layers installer v${VERSION}

Usage:
  ./install.sh [TARGET_DIR] [OPTIONS]

Arguments:
  TARGET_DIR             Directory to install into (default: current directory)

Options:
  --minimal              Install base + roles + template only; skip example projects
  --yes, -y              Non-interactive; assume yes for all prompts
  --help, -h             Show this help
  --version, -v          Show installer version

What gets installed:
  CLAUDE.md                              Layer 1: universal discipline
  .claude/agents/FORGE.md                Layer 2: builder role
  .claude/agents/QUILL.md                Layer 2: writer role
  .claude/agents/SCOUT.md                Layer 2: investigator role
  .claude/agents/WARDEN.md               Layer 2: verifier role (/goal sign-off)
  .claude/commands/goal.md               Slash command: open a /goal manifest
  .claude/commands/goal-verify.md        Slash command: run Warden against a manifest
  .claude/projects/PROJECT_TEMPLATE.md   Layer 3: template
  .claude/projects/PROJECT_WEBAPP.md     Layer 3: example (full install only)
  .claude/projects/PROJECT_API.md        Layer 3: example (full install only)
  .claude/projects/PROJECT_CLI.md        Layer 3: example (full install only)
  .claude/orchestrator/ARGENT.md         Orchestrator config
  .claude/hooks/goal-gate.sh             Stop hook gate for /goal proof enforcement
  .claude/docs/LAYERING_MODEL.md         How layers compose
  .claude/docs/ROUTING_PATTERNS.md       When to use which agent
  .claude/docs/CREATING_OVERLAYS.md      How to write a new overlay
  .claude/docs/GOAL_PROTOCOL.md          /goal manifest + Warden + Stop-hook contract
  .claude/settings.example.json          Reference Stop-hook config for /goal gating

After install:
  1. Review CLAUDE.md at the target's root
  2. Delete project overlays that do not apply to your repo
  3. Copy PROJECT_TEMPLATE.md for your own projects
  4. Update path-to-project mapping in ARGENT.md
  5. Commit the .claude directory to your repo

EOF
  exit 0
fi

# Resolve target dir
if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$(pwd)"
else
  TARGET_DIR="$( cd "$TARGET_DIR" 2>/dev/null && pwd )" || {
    echo "Error: target directory does not exist: $TARGET_DIR"
    exit 1
  }
fi

if [ "$SCRIPT_DIR" = "$TARGET_DIR" ]; then
  echo "Error: source and target are the same directory."
  echo "Run from a different directory or pass a target: ./install.sh /path/to/project"
  exit 1
fi

# Banner
echo ""
echo "claude-layers v${VERSION}"
echo "========================="
echo "Source:  $SCRIPT_DIR"
echo "Target:  $TARGET_DIR"
echo "Mode:    $([ "$MINIMAL" = true ] && echo "minimal" || echo "full (with examples)")"
echo ""

# Confirm unless --yes
if [ "$ASSUME_YES" = false ]; then
  read -p "Install into $TARGET_DIR? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# Helper: copy with overwrite confirmation
copy_with_check() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    echo "  Warning: source file missing: $src"
    return
  fi

  if [ -f "$dst" ]; then
    if [ "$ASSUME_YES" = false ]; then
      echo ""
      echo "Exists: $dst"
      read -p "Overwrite? [y/N] " -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Skipped: $dst"
        return
      fi
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  Wrote: $(realpath --relative-to="$TARGET_DIR" "$dst" 2>/dev/null || echo "$dst")"
}

echo ""
echo "Installing..."
echo ""

# Layer 1: Base CLAUDE.md
echo "  [Layer 1] Base"
copy_with_check "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

# Layer 2: Role overlays
echo ""
echo "  [Layer 2] Roles"
copy_with_check "$SCRIPT_DIR/.claude/agents/FORGE.md"  "$TARGET_DIR/.claude/agents/FORGE.md"
copy_with_check "$SCRIPT_DIR/.claude/agents/QUILL.md"  "$TARGET_DIR/.claude/agents/QUILL.md"
copy_with_check "$SCRIPT_DIR/.claude/agents/SCOUT.md"  "$TARGET_DIR/.claude/agents/SCOUT.md"
copy_with_check "$SCRIPT_DIR/.claude/agents/WARDEN.md" "$TARGET_DIR/.claude/agents/WARDEN.md"

# Slash commands
echo ""
echo "  [Commands]"
copy_with_check "$SCRIPT_DIR/.claude/commands/goal.md"        "$TARGET_DIR/.claude/commands/goal.md"
copy_with_check "$SCRIPT_DIR/.claude/commands/goal-verify.md" "$TARGET_DIR/.claude/commands/goal-verify.md"

# Create goals dir for /goal manifests + proofs
mkdir -p "$TARGET_DIR/.claude/goals"
echo "  Wrote: .claude/goals/ (empty; populated by /goal)"

# Layer 3: Template (always) + examples (full only)
echo ""
echo "  [Layer 3] Projects"
copy_with_check "$SCRIPT_DIR/.claude/projects/PROJECT_TEMPLATE.md" "$TARGET_DIR/.claude/projects/PROJECT_TEMPLATE.md"

if [ "$MINIMAL" = false ]; then
  copy_with_check "$SCRIPT_DIR/.claude/projects/PROJECT_WEBAPP.md" "$TARGET_DIR/.claude/projects/PROJECT_WEBAPP.md"
  copy_with_check "$SCRIPT_DIR/.claude/projects/PROJECT_API.md"    "$TARGET_DIR/.claude/projects/PROJECT_API.md"
  copy_with_check "$SCRIPT_DIR/.claude/projects/PROJECT_CLI.md"    "$TARGET_DIR/.claude/projects/PROJECT_CLI.md"
fi

# Orchestrator
echo ""
echo "  [Orchestrator]"
copy_with_check "$SCRIPT_DIR/.claude/orchestrator/ARGENT.md" "$TARGET_DIR/.claude/orchestrator/ARGENT.md"

# Hooks
echo ""
echo "  [Hooks]"
copy_with_check "$SCRIPT_DIR/.claude/hooks/goal-gate.sh" "$TARGET_DIR/.claude/hooks/goal-gate.sh"
chmod +x "$TARGET_DIR/.claude/hooks/goal-gate.sh" 2>/dev/null || true

# Docs
echo ""
echo "  [Docs]"
copy_with_check "$SCRIPT_DIR/.claude/docs/LAYERING_MODEL.md"    "$TARGET_DIR/.claude/docs/LAYERING_MODEL.md"
copy_with_check "$SCRIPT_DIR/.claude/docs/ROUTING_PATTERNS.md"  "$TARGET_DIR/.claude/docs/ROUTING_PATTERNS.md"
copy_with_check "$SCRIPT_DIR/.claude/docs/CREATING_OVERLAYS.md" "$TARGET_DIR/.claude/docs/CREATING_OVERLAYS.md"
copy_with_check "$SCRIPT_DIR/.claude/docs/GOAL_PROTOCOL.md"     "$TARGET_DIR/.claude/docs/GOAL_PROTOCOL.md"

# Reference settings (example, not active)
echo ""
echo "  [Settings reference]"
copy_with_check "$SCRIPT_DIR/.claude/settings.example.json" "$TARGET_DIR/.claude/settings.example.json"

echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Review CLAUDE.md at $TARGET_DIR/CLAUDE.md"
if [ "$MINIMAL" = false ]; then
  echo "  2. Delete example projects in .claude/projects/ that do not apply to your repo"
fi
echo "  3. Copy PROJECT_TEMPLATE.md to PROJECT_<YOURNAME>.md for new projects"
echo "  4. Update path-to-project mapping in .claude/orchestrator/ARGENT.md"
echo "  5. Read .claude/docs/GOAL_PROTOCOL.md and decide whether to wire the Stop hook from .claude/settings.example.json"
echo "  6. If you enable the Stop hook, ensure jq is installed and set CLAUDE_GOAL_ID for goal-scoped sessions"
echo "  7. Commit the .claude directory to your repo"
echo ""
echo "Quick test in Claude Code:"
echo "  Read CLAUDE.md, then summarize in three sentences what behaviors it requires."
echo ""
echo "Docs: $TARGET_DIR/.claude/docs/"
echo ""
