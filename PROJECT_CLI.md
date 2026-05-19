# PROJECT_CLI.md

**Version:** 1.0.0
**Layer:** 3 of 4 (Project overlay)
**Inherits:** CLAUDE.md + role overlay (Forge/Quill/Scout)

**EXAMPLE OVERLAY.** This file demonstrates the project overlay pattern for a command-line tool. Replace it with your own using `PROJECT_TEMPLATE.md`, or delete it if you have no CLI tool in this repo.

## Project identity

ExampleCLI is a command-line tool distributed as an npm package. Stack: TypeScript compiled to a single executable, commander.js for argument parsing, written for Node.js 20+. Installed globally with `npm install -g example-cli` or run with `npx example-cli`.

## Non-negotiable rules

- Commands exit with non-zero status on any error; never silently succeed
- Destructive operations require `--yes` or interactive confirmation
- Network operations have explicit timeouts; no infinite hangs
- Stdout is for tool output; stderr is for diagnostic messages
- Pipeable output (when `--json` is set) emits valid JSON; no decoration

## Language and naming

- "Command" refers to a top-level subcommand (`example-cli foo`)
- "Flag" refers to options (`--verbose`); "argument" refers to positional args
- Long flags are kebab-case (`--output-dir`); short flags are single letter (`-o`)
- Use "stdout" and "stderr" in code and docs; not "output" alone
- Help text uses imperative voice ("Print the version" not "Prints the version")

## Engineering constraints

- All commands have `--help` text generated from the command definition
- All commands have at least one integration test that runs the actual CLI
- Errors raised with custom error types that carry exit codes
- File operations use absolute paths internally; resolve user-relative paths at the entry point
- Logging uses a leveled logger; no raw `console.log` for diagnostic output

## Active scope

- `src/commands/` is active for new commands
- `src/core/` requires operator review for changes
- Plugin API is stable; breaking changes require major version bump

## Handoff context

- Forge can implement directly
- New commands require Quill-written help text and a README section

## Role-specific notes

### Forge-specific notes when working on this project

- New command requires the command definition, implementation, integration test, and help text
- Argument parsing goes through commander; do not parse process.argv directly
- Avoid global state; commands should be unit-testable

### Quill-specific notes when working on this project

- Help text fits in 80 columns
- README examples include the exact command invocation and the expected output
- Error messages name the specific problem and suggest a remedy

### Scout-specific notes when working on this project

- For "command does the wrong thing" bugs, run the CLI directly and capture both stdout and stderr
- Check the command definition before checking the implementation; routing bugs are common
- Verify the actual installed version matches the version under investigation

## Glossary

| Term | Meaning |
|---|---|
| Command | A top-level subcommand of the CLI |
| Flag | An option passed to a command |
| Argument | A positional argument to a command |
| Plugin | Third-party extension loaded at runtime |

## Open questions

- Auto-update mechanism for global installs
- Telemetry opt-in and what data is collected
