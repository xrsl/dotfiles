---
name: pr-composer
description: Use when opening a PR, or when retitling, relabeling, or rewriting the body of an existing one. Also use when a PR landed in the wrong release-notes section, carries a stale or duplicate label, or has a title the auto-labeler ignored.
---

# Composing PRs

## Overview

The PR title is not decoration — it is the input to an automation chain.
In these repos, `.github/workflows/labeler.yml` parses the Conventional Commit prefix and applies a label, and `.github/release.yml` groups the PR into a release-notes section by that label.
A title the regex doesn't match produces no label, and the PR silently lands in "🔃 Other Changes".

```text
PR title  →  labeler.yml regex  →  label  →  release.yml category  →  release notes section
```

**A repo-local `.claude/skills/pr-composer/SKILL.md` overrides this one.** When there is none, read the repo's own `.github/workflows/labeler.yml` and `.github/release.yml` before trusting the table below — it describes the shared setup, not a guarantee.

## The label chain

The labeler matches `/^([a-zA-Z]+)(\([^)]*\))?!?:/` against the title — a lowercase-able alphabetic type, an optional `(scope)`, an optional `!`, then a colon.
Anything else yields no label at all.

| Title prefix                                  | Label           | Release notes section |
| --------------------------------------------- | --------------- | --------------------- |
| `feat:` / `feature:`                          | `enhancement`   | ✨ Features           |
| `fix:` / `bugfix:`                            | `bug`           | 🐛 Bug Fixes          |
| `docs:` / `doc:`                              | `documentation` | 📚 Documentation      |
| `chore:` `refactor:` `perf:` `test:` `style:` | `chore`         | 🧰 Maintenance        |
| `build:` / `ci:`                              | `ci`            | 🧰 Maintenance        |
| anything else, or no prefix                   | _(none)_        | 🔃 Other Changes      |

Two labels are manual — the workflow never applies them:

- `highlight` — surfaces the PR at the top of the release notes, above Features.
- `skip-changelog` — excludes it from the notes entirely.

## Composing

1. **Read the diff, not the commit log.**
   `gh pr diff <n>` and `gh pr view <n> --json commits`.
   Commit headlines are a work journal; the body should describe the change as it will be read after merge.
1. **Pick the type from what dominates the diff**, not from the largest number of bullets you could write.
   A docs restructure that also adds a test is `docs:`.
   A feature whose diff is mostly test files is still `feat:`.
1. **Add a scope only if it narrows meaningfully** — `feat(authz):`, `fix(probe):`.
   Prefer scopes the repo already uses (`git log --oneline` shows them); skip the scope for repo-wide changes.
1. **Use `!` for breaking changes**: `feat(cli)!: drop --token flags`.
   It does not change the label, so state the break in the body too — and, in a repo with a CHANGELOG, in the entry.
1. **Fill `.github/pull_request_template.md` if the repo has one** — typically What & why, Type of change, Checklist.
   Tick the type box that matches the prefix; ticking a different one contradicts the label.
   With no template, the body is only what you write.
1. **Point at the CHANGELOG rather than duplicating it.**
   Where the repo keeps a `CHANGELOG.md` with an `## [Unreleased]` section (check `AGENTS.md` — several of these repos require an entry for any behavior or surface change), the durable prose belongs there and the PR body is the reviewer's summary.
   If the branch changed behavior and has no CHANGELOG entry, that is a gap worth naming in the PR body.
1. **Link the issue the PR resolves.**
   Look for it in the branch name (`fix-123-…`, `issue-123`), commit messages (`#123`, `Fixes #123`), and open issues matching the change (`gh issue list --state open --search "<keywords>"`, then `gh issue view <n>` to confirm).
   When one clearly matches, put `Closes #<n>` on its own line in the body so GitHub links it and closes it on merge; use one line per issue.
   If a match is only related and not resolved by this PR, write `Refs #<n>` instead.
   Never invent an issue number; with no confident match, omit the line.
1. **Keep the body short.**
   Sections with a few bullets each.
   A reviewer should get the shape of the change in fifteen seconds and read the diff for the rest.
1. **Flag what's still open.**
   If the branch has a known gap or a deliberate omission, say so in a short "Known" note rather than letting a reviewer discover it.

Apply with `gh pr edit <n> --title "..." --body-file <path>`, writing the body to a scratch file first so the markdown survives shell quoting.

## The stale-label trap

`labeler.yml` calls `addLabels` and **never removes anything**.
It runs on `opened`, `edited`, `reopened`, and `synchronize` — so retitling a PR from `feat:` to `docs:` adds `documentation` and leaves `enhancement` in place.
The PR then matches two categories, and `release.yml` files it under whichever comes first in that file (Features beats Documentation).

**After changing a PR's type prefix, always remove the old label yourself:**

```bash
gh pr edit <n> --remove-label enhancement
gh pr view <n> --json labels --jq '.labels[].name'   # verify exactly one type label
```

## The missing-label trap

`release.yml` may name labels the repo has never defined — `chore`, `highlight`, and `skip-changelog` are the usual gaps.

The workflow's `addLabels` call creates a missing label on the fly (that is why an undescribed, default-grey `ci` label appears in repos that have merged one `ci:` PR). `gh pr edit --add-label` gives no such grace — it resolves the name against the repo's labels first and fails when there is no match.

So a PR labeled by hand (or by `wt pr`, which reconciles labels itself rather than waiting for the workflow) cannot carry a label the repo lacks:

```bash
gh label list | grep -qx chore || gh label create chore --description "Maintenance" --color ededed
```

Check before relying on a label the repo has never used.

## Common mistakes

| Mistake                                     | Consequence                                              |
| ------------------------------------------- | -------------------------------------------------------- |
| Title is a bare branch name (`upt docs`)    | Regex misses, no label, "Other Changes"                  |
| `Docs:` or `DOCS:`                          | Fine — the workflow lowercases the captured type         |
| `docs -` or `docs;` instead of `docs:`      | Regex misses, no label                                   |
| Retitled without removing the old label     | Two labels, wrong release-notes section                  |
| Body pasted from commit headlines           | Reads as a work journal, not a description of the change |
| Behavior change with no CHANGELOG entry     | Docs-site release notes never mention it                 |
| `!` in the title but no breaking-change note | Consumers upgrade blind                                  |
| `highlight` expected to apply automatically | It never does; add it by hand                            |
| Type box ticked doesn't match the prefix    | Template contradicts the label                           |

## Verifying

The labeler runs on edit, so a title fix is observable within a few seconds:

```bash
gh pr view <n> --json title,labels --jq '{title, labels: [.labels[].name]}'
```

One type label, matching the prefix, means the release notes will categorize correctly.
