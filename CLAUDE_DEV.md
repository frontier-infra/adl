# CLAUDE_DEV.md

This file provides guidance to Claude Code (claude.ai/code) when working on the **adl repo itself** — not when running inside a project that consumes adl.

Claude Code only auto-loads `CLAUDE.md` at the project root. That file is the Layer 1 product this repo ships. To use this file, point Claude at it explicitly: `read CLAUDE_DEV.md before making changes here`.

## What this repo is

A distribution package, not an application. It contains:

- A bash installer (`install.sh`)
- A set of behavioral overlay markdown files that the installer copies into a target project under a `.claude/` directory tree

There is no build step, no test suite, no runtime. The "product" is the markdown content plus the installer that delivers it.

## The product / repo-layout split

Source overlay files live under `.claude/` mirroring their destination layout. The source tree **is** the install tree — `install.sh` copies file-for-file:

| Source path                                     | Installed at target as                          | Layer        |
|-------------------------------------------------|-------------------------------------------------|--------------|
| `CLAUDE.md`                                     | `<target>/CLAUDE.md`                            | 1 (base)     |
| `.claude/agents/FORGE.md` / `QUILL.md` / `SCOUT.md` / `WARDEN.md` | `<target>/.claude/agents/<NAME>.md` | 2 (role) |
| `.claude/commands/goal.md` / `goal-verify.md`   | `<target>/.claude/commands/<NAME>.md`           | slash commands |
| `.claude/projects/PROJECT_TEMPLATE.md` / `PROJECT_WEBAPP.md` / `PROJECT_API.md` / `PROJECT_CLI.md` | `<target>/.claude/projects/<NAME>.md` | 3 (project)  |
| `.claude/orchestrator/ARGENT.md`                | `<target>/.claude/orchestrator/ARGENT.md`       | orchestrator |
| `.claude/docs/LAYERING_MODEL.md` / `ROUTING_PATTERNS.md` / `CREATING_OVERLAYS.md` / `GOAL_PROTOCOL.md` | `<target>/.claude/docs/<NAME>.md` | docs |
| `.claude/settings.example.json`                 | `<target>/.claude/settings.example.json`        | settings (reference) |

The installer also creates an empty `<target>/.claude/goals/` directory; manifests and proofs land there via the `/goal` and `/goal-verify` slash commands.

Editing any of these is a product change. Treat them like releasable artifacts:

- Bump the `Version:` line at the top of the file when behavior changes.
- Voice: direct, declarative, no hedging. No em-dashes (use colons, periods, semicolons). Examples before abstractions. Match the surrounding overlay structure exactly. (See `CONTRIBUTING.md`.)
- Editing `CLAUDE.md` (the Layer 1 base) propagates to every downstream consumer. Be especially careful with it.

Repo-development files that do **not** ship to consumers (stay at repo root, untouched by `install.sh`): this file, `install.sh`, `.gitignore`, `README.md`, `CONTRIBUTING.md`, `AI_INSTALL.md`, `CHANGELOG.md`, `LICENSE`, `validate.yml`.

## Known structural issue (verify before "fixing")

**`validate.yml` location.** The file is a GitHub Actions workflow but sits at the repo root rather than `.github/workflows/validate.yml`. Actions will not pick it up where it currently is. Surface this; do not silently move it without confirming with the maintainer.

## Commands

```bash
./install.sh                    # install into current directory (interactive)
./install.sh /path/to/project   # install into a specific target
./install.sh --minimal          # base + roles + template + orchestrator + docs only (skip example projects)
./install.sh --yes              # non-interactive; accept defaults
./install.sh --help             # full usage
./install.sh --version          # print installer version

bash -n install.sh              # syntax-check the installer
shellcheck install.sh           # lint the installer (used in CI)
```

To verify the installer end-to-end (mirrors `validate.yml`):

```bash
TMP=$(mktemp -d)
./install.sh "$TMP" --yes                  # full install
./install.sh "$TMP" --yes                  # second run = idempotency test
./install.sh "$TMP" --minimal --yes        # minimal install path
test -f "$TMP/CLAUDE.md" && test -f "$TMP/.claude/agents/FORGE.md"  # sanity
```

## Smoke test of the installed layers

After installing into a target, drop into a Claude Code session in that target and run:

```
Read CLAUDE.md, then summarize in three sentences what behaviors it requires.
```

A correct response mentions: read before write, surface confusion before acting, surgical edits. If any are missing, the file did not load.

## Editing overlays — guardrails from the maintainer

From `CONTRIBUTING.md`, repeated here because they bind any edit:

- **Do not relax precedence rules.** Lower layers win. This is foundational. Any change that lets a higher layer override a lower one is rejected.
- **Do not conflate role and project concerns.** Role overlays (`FORGE` / `QUILL` / `SCOUT`) describe behavior; project overlays describe values and constraints. Keep them separate.
- **Do not add new required dependencies.** The installer is bash on purpose.
- **Do not add auto-update or auto-detection magic.** Users pull updates explicitly.
- New role/project overlay PRs must include: version line, identity, what-you-own, what-you-do-not-own, discipline, failure modes, handoff protocol. Write the "what you do not own" section first.

## Releasing

`CHANGELOG.md` follows Keep a Changelog. The pinned `adl-v1.0.0.tar.gz` at the repo root is the v1.0.0 release artifact. There is no automated release pipeline; bumping `VERSION` in `install.sh` and updating `CHANGELOG.md` are manual steps.
