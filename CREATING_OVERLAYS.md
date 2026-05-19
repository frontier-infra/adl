# Creating Project Overlays

How to write a new `PROJECT_<NAME>.md` overlay that composes correctly with the rest of the stack.

## Start from the template

```bash
cp .claude/projects/PROJECT_TEMPLATE.md .claude/projects/PROJECT_MYPROJECT.md
```

Edit the new file. Bump the version each time you change it after the initial draft.

## What goes in a project overlay

A project overlay encodes things that are:

- **True for this project specifically.** If it would apply to every project, it belongs in CLAUDE.md.
- **True regardless of which agent is working.** If it only applies to one role, scope it inside the role-specific notes section.
- **Stable enough to live in a file.** If it changes every week, it belongs in task context, not the overlay.

## What does not go in a project overlay

- Universal coding discipline (that is base CLAUDE.md)
- Role behavior (that is the role overlay)
- Task-specific constraints for this exact invocation (that is task context)
- Speculation about future product direction (that is a planning doc, not an overlay)
- Personal preferences with no operational impact

## Required sections

### Project identity

One paragraph. Name, purpose, owning entity (if applicable), key tech stack. Enough that an agent reading this with no prior context knows what the project is.

### Non-negotiable rules

The handful of constraints that must never be relaxed. These are the rules where violating them causes legal, financial, security, or reputational harm. Keep this section short. If everything is non-negotiable, nothing is.

### Language and naming

The vocabulary the project uses. Especially important when terms have specific meaning that an agent might otherwise misuse.

### Engineering constraints

Technical rules that apply to all code work in this project. Test requirements, library choices, architectural invariants.

### Active scope

What is being worked on, what is frozen, what requires approval. This section changes often; that is fine, bump the version.

### Handoff context

Who implements work, in what format, with what review gates.

### Role-specific notes

Three subsections: Forge, Quill, Scout. What does each role need to know that is specific to this project?

## Optional sections

### Glossary

A table of project-specific terms. Useful when the project has its own vocabulary that an agent would not infer.

### Open questions

Things the operator has not yet decided. Agents should not assume answers; they should escalate. Keep this list current.

## Good vs. bad examples

### Good non-negotiable rule

> Multi-tenant isolation is mandatory; flag any code that crosses tenant boundaries.

This is specific, testable, and tells the agent what to do when it sees a violation.

### Bad non-negotiable rule

> Write high-quality code.

This is not actionable. It belongs nowhere.

### Good engineering constraint

> Webhook handlers need replay-safe idempotency keys; missing keys are a defect.

Specific, verifiable, and tells the agent how to treat violations.

### Bad engineering constraint

> Be careful with webhooks.

This is not actionable. Cut it.

### Good language rule

> Use "verified finding" not "potential vulnerability."

Specific, copy-and-pasteable, the agent can apply it immediately.

### Bad language rule

> Use professional language.

Vague. Every agent will interpret this differently.

## Version discipline

Bump the version when:

- You change a non-negotiable rule
- You change active scope
- You change a role-specific instruction
- You change language or naming

Do not bump for typo fixes or whitespace changes.

## Review checklist

Before committing a new or changed overlay:

- [ ] Version is bumped if behavior changed
- [ ] Project identity reads cleanly to someone with no context
- [ ] Non-negotiable rules are short, specific, and actionable
- [ ] Language rules give the exact correct wording
- [ ] Engineering constraints are testable
- [ ] Active scope reflects current reality, not aspiration
- [ ] Handoff context names the implementer and format
- [ ] Role-specific notes are written for each of Forge, Quill, Scout
- [ ] Glossary covers terms an outside agent would not know
- [ ] Open questions are current; nothing stale

## Anti-patterns

### Overlay duplicates base CLAUDE.md

If a project overlay says "write surgical edits, do not refactor adjacent code," it is duplicating CLAUDE.md. Delete it. The base rule is already inherited.

### Overlay duplicates role overlay

If a project overlay says "Forge: write tests before implementing," it duplicates FORGE.md. Delete it. The role rule is already inherited.

### Overlay tries to relax a rule

If a project overlay says "Forge: it is okay to refactor adjacent code in this project," it is trying to relax CLAUDE.md section 5. The base rule wins, and the project overlay is misleading. Delete the relaxation.

### Overlay becomes a wishlist

If the active scope section reads more like a roadmap than a constraint, you are using the overlay as a planning doc. Move planning content elsewhere. The overlay describes what is true now.

### Overlay is too long

A project overlay that exceeds a few pages is doing too much. Most of it is probably:

- Duplicated from base or role overlays (delete)
- Speculative or aspirational (move to planning docs)
- Task-specific rather than project-specific (move to task context)

A tight project overlay is more useful than a sprawling one.

## Promoting a constraint up the stack

Sometimes you discover that what you put in a project overlay actually applies everywhere. Move it up.

- If a "project rule" applies to every project you have → promote to base CLAUDE.md
- If a "project rule" applies to every project of a certain type → consider a new role overlay
- If a "project rule" only applies once in a while → demote to task context

The reverse also happens. Something in CLAUDE.md might be too aggressive for a specific project. The right move is rarely to add an exception in the project overlay. The right move is to ask whether the base rule is correct.
