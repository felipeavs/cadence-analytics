# ADR 003: Automate versioning and changelog with python-semantic-release

**Status:** Accepted
**Date:** 2026-08-07

## Context

The project needs a way to track which version of the code is running, and a
readable history of what changed between versions. Doing this by hand — bumping
a version number, writing a changelog entry, tagging the commit, publishing a
release — is four manual steps that are easy to forget or do inconsistently,
especially on a solo project where nothing enforces the discipline.

Since commit messages were already going to follow Conventional Commits, the
information needed to derive all four steps already exists in the commit
history: `feat:` implies a minor bump, `fix:` a patch, and the commit subjects
are the changelog entries.

## Decision

Use `python-semantic-release` to derive version numbers, update the changelog,
create tags and publish GitHub Releases automatically, triggered by pushes to
`main`.

Versioning happens **only** on `main`. The `develop` branch accumulates work
without producing versions; a release is cut when `develop` is merged into
`main`.

## Rationale

The alternative — versioning on both `main` and `develop` — was considered and
rejected. Both branches would compute a version from the same commits, which
either produces duplicate tags or causes the version numbers to drift apart
between branches. Both branches would also write to the same `CHANGELOG.md`,
producing a merge conflict on every promotion from `develop` to `main`. The
single-release-branch model is the tool's design assumption, and working against
it creates problems it was built to avoid.

Pre-release versions on `develop` (`0.2.0-rc.1`) would have been the supported
way to get versioning on both branches, but for a solo project the extra tags
add noise without a consumer who benefits from them.

## Consequences

### Positive

- Version numbers, changelog and releases are always consistent with the commit
  history, with no manual step to forget.
- Commit message discipline now has a visible payoff, which reinforces it.
- The release history doubles as project documentation.

### Negative

- Commits that do not follow Conventional Commits are silently ignored when
  computing the version. A change committed as `"fixes"` instead of `"fix:"`
  will not appear in the changelog and will not trigger a release.
- Only `feat`, `fix` and `perf` produce a version bump. A release consisting
  entirely of `chore`, `docs` or `ci` commits produces no new version — which is
  correct behaviour, but can look like a failure if unexpected.

## Configuration notes

Three configuration details caused silent failures during setup and are recorded
here because none of them produce an obvious error message:

**The command is `semantic-release version`, not `publish`.** In v8 the commands
were reorganised; `publish` still exists but uploads artifacts to an existing
release rather than creating one. Using it produces no release and no error.

**`CHANGELOG.md` must contain the insertion marker.** The changelog is
configured with `mode = "update"`, which inserts new entries at a marker rather
than rewriting the file. Without `<!-- version list -->` present in the file,
the tool has nowhere to write and skips the changelog step silently. The marker
must not be removed when editing the changelog by hand.

**`__version__.py` must contain a Python assignment.** The `version_variables`
setting looks for the pattern `__version__ = "..."`. A file containing only a
bare version number is not matched and is left untouched — again, without an
error.

The loop guard depends on `commit_message` containing `[skip ci]`: the tool's
own release commit is a push to `main`, which would otherwise re-trigger the
workflow indefinitely. If the commit message template is changed, the guard must
be preserved.

### Revisit when

If the project ever gains a second contributor or a real deployment target,
pre-release versions on `develop` become worth reconsidering — at that point
there is an actual consumer who benefits from being able to reference a specific
in-development build.