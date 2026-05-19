# AI Install Instructions

This document tells a Claude Code instance how to install `claude-layers` into a user's project when the user points it at this repository.

If you are a human reading this, you do not need to follow these instructions. Run `./install.sh` instead. This file exists for the case where a user says to their Claude Code agent: *"Go install claude-layers from this repo into my project."*

---

## Your role

You are a Claude Code agent. The user has pointed you at the `claude-layers` repository and asked you to install it into their project. You need to:

1. Understand what the user wants installed
2. Verify the target directory
3. Copy the files into the correct locations
4. Confirm the install worked
5. Tell the user what to do next

Do not improvise beyond these steps. If anything is unclear, ask before acting.

## Pre-install checks

Before copying any files:

1. **Confirm the target directory.** Ask the user where they want this installed if it is not obvious from the conversation. The target should be the root of their Claude Code project. Common signals: a directory containing `package.json`, `pyproject.toml`, `Cargo.toml`, or an existing `CLAUDE.md`.

2. **Check for an existing `CLAUDE.md`.** If one exists at the target, do not overwrite without asking. The user may have local customizations. Offer to back it up to `CLAUDE.md.backup` before proceeding.

3. **Check for an existing `.claude/` directory.** Same rule: do not overwrite without asking. If files exist, list them and ask which the user wants overwritten.

4. **Confirm the install mode.** Two options:
   - **Full:** base + 3 role overlays + template + 3 example projects + orchestrator + docs
   - **Minimal:** base + 3 role overlays + template + orchestrator + docs (no example projects)
   
   Ask which the user wants. Default to full if they have no preference.

## File map

Copy from the `claude-layers` repository to the user's target directory:

| Source | Destination | Always installed |
|---|---|---|
| `CLAUDE.md` | `<target>/CLAUDE.md` | Yes |
| `.claude/agents/FORGE.md` | `<target>/.claude/agents/FORGE.md` | Yes |
| `.claude/agents/QUILL.md` | `<target>/.claude/agents/QUILL.md` | Yes |
| `.claude/agents/SCOUT.md` | `<target>/.claude/agents/SCOUT.md` | Yes |
| `.claude/projects/PROJECT_TEMPLATE.md` | `<target>/.claude/projects/PROJECT_TEMPLATE.md` | Yes |
| `.claude/projects/PROJECT_WEBAPP.md` | `<target>/.claude/projects/PROJECT_WEBAPP.md` | Full only |
| `.claude/projects/PROJECT_API.md` | `<target>/.claude/projects/PROJECT_API.md` | Full only |
| `.claude/projects/PROJECT_CLI.md` | `<target>/.claude/projects/PROJECT_CLI.md` | Full only |
| `.claude/orchestrator/ARGENT.md` | `<target>/.claude/orchestrator/ARGENT.md` | Yes |
| `.claude/docs/LAYERING_MODEL.md` | `<target>/.claude/docs/LAYERING_MODEL.md` | Yes |
| `.claude/docs/ROUTING_PATTERNS.md` | `<target>/.claude/docs/ROUTING_PATTERNS.md` | Yes |
| `.claude/docs/CREATING_OVERLAYS.md` | `<target>/.claude/docs/CREATING_OVERLAYS.md` | Yes |

Create destination directories as needed.

## Install procedure

For each file in the file map:

1. Read the source file from the `claude-layers` repository.
2. Check if the destination exists.
3. If it exists, ask the user before overwriting. (Skip this step if the user said "overwrite all" earlier.)
4. Write the file to the destination.
5. Verify the write by reading the destination back and confirming it matches.

Do not modify file contents during copy. The files install as-is.

## Post-install verification

After all files are copied:

1. List the files installed. Group them by layer for clarity.
2. Run a smoke test: ask the user to run the following in their Claude Code session:

   ```
   Read CLAUDE.md, then summarize in three sentences what behaviors it requires.
   ```

   A correct response from their Claude Code agent will mention reading before writing, surfacing confusion before acting, and surgical edits. If the response is missing any of these, the file did not load correctly.

3. Tell the user the next steps:
   - Review `CLAUDE.md` at the project root
   - Delete project overlay examples that do not apply to their repo (full install only)
   - Copy `PROJECT_TEMPLATE.md` for their own projects
   - Update the path-to-project mapping in `.claude/orchestrator/ARGENT.md`
   - Commit the `.claude` directory to their repo

## Edge cases

### The user already has a CLAUDE.md

Do not overwrite without confirmation. Options to offer:

- **Replace:** back up the existing file to `CLAUDE.md.backup` and install the new one
- **Merge:** show both files and ask the user which sections to keep
- **Skip:** leave the existing file in place; install only the other layers

If you merge, do it conservatively. The user's existing rules go first; this packet's rules go after. Surface any direct contradictions for the user to resolve.

### The user has an existing .claude/agents/ with custom agents

Do not overwrite. Install the new files only where they do not conflict. List any files you skipped at the end.

### The user is in a non-empty directory that is not a code project

Confirm with the user before installing. Ask: "I do not see typical project markers (package.json, pyproject.toml, etc.) here. Is this the right directory?" Wait for confirmation.

### The user wants to install across multiple projects

Install into one project at a time. Do not auto-discover sibling directories.

### Repo content has changed since these instructions were written

If you find file map entries pointing to source files that do not exist, or new files in the repo not in the file map, stop and ask the user. Do not improvise the file map.

## What you will not do

- Modify any file contents during install
- Install into directories outside the user's specified target
- Run any scripts other than file copies
- Suggest the user install additional tools or packages
- Make changes to the user's existing files except the explicit overwrites confirmed above

## Reporting back

When done, your final message to the user includes:

1. Files installed (grouped by layer)
2. Files skipped (with reason)
3. Files that need user action (e.g., path-to-project mapping in `ARGENT.md`)
4. The smoke test command to run
5. The next steps list

Keep it short. The user does not need a recap of the layering model; they have the docs for that.
