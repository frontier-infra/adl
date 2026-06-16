# Contributing to adl

Thanks for considering a contribution. This document describes what kinds of changes are in scope and how to propose them.

## What this project is

`adl` is an opinionated configuration system. The opinions are the value. Contributions should sharpen the opinions or expand the surface where they apply, not blunt them.

## What is in scope

- **Additional example project overlays** for common project shapes (mobile app, library, monorepo, ML pipeline, infrastructure-as-code, etc.)
- **Additional role overlays** that have proven useful in practice (e.g., a security reviewer, a performance specialist, a UX writer)
- **Bug fixes** in the installer
- **Documentation improvements** that make the layering model clearer
- **Tightening of existing rules** where the current language is ambiguous

## What is out of scope

- **Changes that relax precedence rules.** The lower-wins rule is foundational and not negotiable.
- **Changes that conflate role and project concerns.** Keep layers separate.
- **Decoration without operational impact.** Pretty headers, banners, or unnecessary structure.
- **Tooling that requires new dependencies.** The installer is bash for a reason. Suggestions for separate companion tools are welcome but go in a separate repo.
- **Auto-update mechanisms.** Users should pull updates explicitly.

## How to propose a change

For small changes (typos, wording fixes), open a PR directly.

For larger changes (new roles, new examples, structural changes), open an issue first and describe:

1. What problem you are solving
2. Why the existing layers do not solve it
3. What you propose to add or change
4. How it composes with the precedence rules

The maintainers will discuss before you spend time on the PR.

## Standards for new overlays

If you are proposing a new role overlay or project overlay:

- Follow the structure of the existing overlays exactly
- Include version line, identity, what-you-own, what-you-do-not-own, discipline, failure modes, handoff protocol
- Write the "what you do not own" section first; it is the hardest and most important
- Keep total length similar to existing overlays
- Include a brief PR description explaining the use case

## Standards for documentation changes

- Match the existing voice: direct, declarative, no hedging
- No em-dashes; use colons, periods, or semicolons
- Examples before abstractions
- Every code snippet must actually run, or be marked illustrative

## Testing changes

The installer is a bash script. Test changes by:

1. Running `bash -n install.sh` to syntax-check
2. Running the installer into a temporary directory
3. Running it again to verify idempotency
4. Running with `--minimal` and `--yes` flags

## What we will say no to

- New required dependencies
- New default opinions that contradict existing ones
- Renaming things for style reasons
- Adding configuration knobs without a clear use case
- Auto-detection magic that hides what the installer is doing
