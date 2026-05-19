# Changelog

All notable changes to claude-layers will be documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-05-19

### Added

- `WARDEN.md` role overlay: verifier agent that closes the `/goal` loop by running declared `done_when` checks and writing a signed proof artifact
- `/goal` slash command (`.claude/commands/goal.md`): writes a verifiable manifest at `.claude/goals/<task-id>.yaml` before work is dispatched
- `/goal-verify` slash command (`.claude/commands/goal-verify.md`): invokes Warden against a manifest and writes `.claude/goals/<task-id>.proof.json`
- `GOAL_PROTOCOL.md`: full specification of manifest schema, check types (`test`, `command`, `file_exists`, `file_contains`, `diff_constraint`, `human_review`), proof artifact, sign-off states, kickback routing, and Stop-hook contract
- `settings.example.json`: reference Stop-hook configuration that blocks worker termination until `signed_off: true`

### Changed

- `CLAUDE.md` §6 (Goal-driven loops): when `/goal` protocol is installed, the canonical success criterion is the manifest + Warden proof, not agent self-assessment. Bumped to v1.1.0.
- `ARGENT.md`: added a binding "dispatch contract" — every worker spawn must name a role overlay, a project overlay, and reference a `/goal` manifest. Refuses to dispatch generic / general-purpose workers. Bumped to v1.1.0.
- `ROUTING_PATTERNS.md`: added Warden to classification table, decomposition rule, pipeline pattern, and failed-delegation recovery
- `install.sh`: bumped to v1.1.0; installs new role overlay, slash commands, protocol doc, settings example; creates `.claude/goals/` directory
- `validate.yml`: extended file-presence checks for the new artifacts

## [1.0.0] - 2026-05-19

### Added

- Base `CLAUDE.md` with eight numbered behavioral guidelines
- Three role overlays: `FORGE.md` (builder), `QUILL.md` (writer), `SCOUT.md` (investigator)
- Project overlay template at `PROJECT_TEMPLATE.md`
- Three example project overlays: `PROJECT_WEBAPP.md`, `PROJECT_API.md`, `PROJECT_CLI.md`
- Orchestrator configuration at `ARGENT.md`
- Documentation: `LAYERING_MODEL.md`, `ROUTING_PATTERNS.md`, `CREATING_OVERLAYS.md`
- Bash installer at `install.sh` with `--minimal`, `--yes`, and `--help` flags
- AI install instructions at `AI_INSTALL.md` for Claude Code agents installing on a user's behalf
- MIT license

[1.1.0]: https://github.com/frontier-infra/claude-layers/releases/tag/v1.1.0
[1.0.0]: https://github.com/frontier-infra/claude-layers/releases/tag/v1.0.0
