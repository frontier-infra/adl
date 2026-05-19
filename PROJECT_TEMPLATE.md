# PROJECT_TEMPLATE.md

**Version:** 1.0.0
**Layer:** 3 of 4 (Project overlay)
**Inherits:** CLAUDE.md + role overlay (Forge/Quill/Scout)

Template for new project overlays. Copy this file to `PROJECT_<NAME>.md`, fill in the sections, and bump the version each time you change it.

This overlay encodes project-specific values, constraints, and language. It does not override base CLAUDE.md or role overlays. It adds constraint on top of them.

## Project identity

One paragraph naming the project, its purpose, and any owning entity. Include any official taglines or non-negotiable brand lines.

Example shape:
> ProjectName is the [what it does] for [audience]. Tech stack: [list]. Repository: [path].

## Non-negotiable rules

The handful of constraints that cannot be relaxed by any agent, ever. These are the rules that, if violated, cause real harm (legal, financial, reputational, security).

Example shape:
- [Specific testable rule]
- [Specific testable rule]
- [Specific testable rule]

Keep this section short. If everything is non-negotiable, nothing is.

## Language and naming

Project-specific vocabulary. The exact words agents should use and not use.

Example shape:
- Use "[term]" not "[alternative]"
- Module names: [list]; do not improvise abbreviations
- [Product] is the platform; [components] are the modules

## Engineering constraints

Technical rules that apply to all code work in this project.

Example shape:
- All migrations must include a rollback plan
- External API calls must be mockable in tests
- Secrets never live in the repository

## Active scope

What is currently being worked on, and what is frozen.

Example shape:
- `[path/to/active]` is the current focus
- `[path/to/frozen]` is frozen; do not propose changes without explicit approval

## Handoff context

Who implements work for this project, and in what format.

Example shape:
- Dev work goes to [agent/person] via [format]
- Quill output for engineering should be in [format]

## Role-specific notes

### Forge-specific notes when working on this project

Constraints that apply to Forge specifically when building in this project.

### Quill-specific notes when working on this project

Constraints that apply to Quill specifically when writing for this project.

### Scout-specific notes when working on this project

Constraints that apply to Scout specifically when investigating this project.

## Glossary

Project-specific terms a new agent would not recognize.

| Term | Meaning |
|---|---|
| [Term] | [Definition] |

## Open questions

Things the operator has not yet decided. Agents should not assume answers; they should escalate.

- [Open question 1]
- [Open question 2]
