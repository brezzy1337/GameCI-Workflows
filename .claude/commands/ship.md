---
description: Open a PR into stable, post it to Discord, run the multi-lens review, optionally run UBA tests, and merge — with approval gates before opening and merging
argument-hint: [short summary of the change]
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(git merge-base *), Bash(git fetch *), Bash(gh pr view *), Bash(gh pr list *), Bash(gh pr diff *), Bash(gh pr checks *), Bash(gh run list *), Bash(gh run view *), Bash(unity vcs doctor *), Bash(unity editors path *), Bash(.claude/scripts/discord-notify.sh *), Read, Grep, Glob
---

# Ship

Context (gathered for you):
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Existing PR: !`gh pr view --json number,state,url,labels --jq '"#\(.number) \(.state) \(.url) labels=\([.labels[].name]|join(","))"' 2>/dev/null || echo none`
- Diff stat vs stable: !`git fetch -q origin stable && git diff --stat origin/stable...HEAD`

Run the ship pipeline for the current branch. Treat $ARGUMENTS as an optional one-line summary of
the change. PRs always target **`stable`** (see Branching in CLAUDE.md). The chain is sequential
and you (the central thread) own it — the specialists have no `Agent` tool. The agents named below
come from the claude-unity-devkit plugin: invoke them as `claude-unity-devkit:<name>`.

**Resume, don't restart.** If a PR already exists for this branch, skip to the first stage that
isn't done: it's open → don't re-post to Discord; review comment already posted → go to CI; merged
or closed (someone may have merged it on GitHub from the Discord link) → report that and stop.

0. **Sanity.** Refuse to ship from `stable` or `main`. Uncommitted changes → stop and list them;
   never commit on the user's behalf here.

1. **Preflight.** Run `unity vcs doctor` (meta files, LFS, merge settings — the same checks as the
   pre-commit hook). If `unity editors path <version from ProjectSettings/ProjectVersion.txt>`
   succeeds, this machine has the Editor: also run
   `unity test --affected --since origin/stable --mode EditMode` (close the Editor first; it will
   prompt). Otherwise say the UBA run in step 5 is the only test gate. If the diff touches
   `Packages/manifest.json`, `Packages/packages-lock.json`, DLLs under `Assets/Plugins/`, Asset
   Store content, or `uses:` lines in workflows, delegate to `dependency-auditor` and stop on NO-GO.
   A red preflight stops the pipeline — report what failed.

2. **Draft the PR.** Delegate to `pr-author` for a title and body from `git diff origin/stable...HEAD`.
   **GATE 1 — do not open the PR yet.** Show me the draft and wait for my explicit "yes". Then
   `git push -u origin <branch>` and `gh pr create --base stable --title … --body-file -`. Neither is
   pre-authorized, so both prompt — that prompt is the gate.

3. **Notify Discord (once).** Right after the PR is created, run
   `.claude/scripts/discord-notify.sh "<pr url>" "<pr title>" "<one-line summary>"`. This is the only
   Discord post — people open the PR on GitHub from it. If it exits 3 (`DISCORD_WEBHOOK_URL` not
   set) or fails, say so in one line and continue; a missed notification never blocks shipping.

4. **Review (fan-out, then consolidate).** Scale the panel to the diff: docs-only or trivial → one
   lens or skip. Substantive → dispatch in parallel, read-only: `factual-reviewer`,
   `architecture-reviewer`, `security-reviewer`, `consistency-reviewer`, `redundancy-checker`. Add
   `gameplay-reviewer` + `performance-reviewer` for `Assets/**/*.cs` runtime code (and
   `performance-reviewer` for physics/quality/graphics settings), `ci-reviewer` for
   `.github/workflows/**` or `.github/scripts/**`. Consolidate yourself — merge, resolve conflicts
   between lenses, de-duplicate, rank by impact — and post ONE review comment with a single overall
   verdict (`gh pr comment`, which prompts). Summarize blocking issues for me.

5. **CI (ask per PR).** PRs only run tests in Unity Build Automation when labeled `cloud-ci`
   (~20 min of the 200 free Windows minutes/month). Recommend yes when the diff touches `Assets/`,
   `Packages/`, or `ProjectSettings/`; no for docs/CLAUDE.md-only. Ask me. If yes,
   `gh pr edit <n> --add-label cloud-ci` (prompts), then wait with `gh pr checks <n> --watch`; a red
   `UBA build + tests` check is blocking — pull the summary with `gh run view`. If no, note at the
   merge gate that tests first run on the post-merge `stable` build.

6. **GATE 2 — do not merge yet.** Show me the consolidated review, the CI status (or "not run"), and
   your recommendation, and wait for my explicit "yes". Then
   `gh pr merge <n> --merge --delete-branch` (prompts). If the PR was already merged on GitHub, just
   report it.

Never work around a gate, a red preflight, a failing check, or a blocking review to ship faster. If
something blocks, stop and tell me why.
