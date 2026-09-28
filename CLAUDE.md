# GameCI-Workflows

Unity 6000.6.3f1 (URP) project. Set up with the claude-unity-devkit `unity-init` skill.

## Branching

- `main` = production (release merges + `v*` tags only). `stable` = integration; PRs target `stable`,
  and `/claude-unity-devkit:code-todo` and `/claude-unity-devkit:ship` use it as the base branch.
- Branch from `stable`: `feature/<name>` (code and systems), `level/<name>` (levels and characters),
  `art/<name>` (asset batches). Keep branches short-lived; hide unfinished mechanics behind a flag and
  merge early.
- Scenes (`*.unity`) and in-place-edited art (`*.psd`, `*.fbx`, `*.blend`) are `lockable`: they check
  out read-only. Lock before editing (`git lfs lock <path>`), unlock after your PR merges.
- Releases: PR `stable` → `main`, then tag `vX.Y.Z` on `main`. Hotfixes go to `main` and are merged
  back into `stable` the same day.

## Unity CLI

Pinned CLI: `1.0.0-beta.11` (beta channel) · Editor: `6000.6.3f1` · Windows builds need no extra
module on Windows. The Editor is installed only on people's own machines — never in Codespaces or
other cloud dev environments, which get the CLI only.

| When | Run |
| --- | --- |
| New machine (Windows) | `winget install Unity.CLI`, `unity self-update --target 1.0.0-beta.11 --yes`, then `unity install 6000.6.3f1 --accept-eula --yes` (or Unity Hub) |
| New machine (macOS/Linux) | `curl -fsSL https://unity.com/install.sh \| UNITY_CLI_CHANNEL=beta UNITY_CLI_VERSION=1.0.0-beta.11 bash` |
| New clone | `git lfs install --local && unity vcs merge-setup && unity vcs hooks install` (`merge-setup` needs the Editor — skip it in Codespaces) |
| Get latest | `unity vcs sync` (close the Editor first) |
| Change branch | `unity vcs switch <branch>` |
| Before pushing | `unity test --affected --since origin/stable --mode EditMode` |
| Opening a PR | `unity vcs summarize --since origin/stable` → paste into the PR |
| Scene/prefab merge conflict | `unity vcs conflicts`, `unity vcs explain <path>`, `unity vcs resolve --all` |
| Try a build locally | `unity build --target StandaloneWindows64 -o Build/GameCIWorkflows.exe`, then `unity build run` |
| Something's off | `unity doctor` |

`com.unity.pipeline` (0.8.0-exp.1) is installed: with the Editor open, `unity command` lists and runs
Editor commands, and static methods marked `[CliCommand]` become team commands.

## CI

- Workflow: `.github/workflows/cloud-build.yml` → `.github/scripts/uba-build.sh`. Builds run in
  **Unity Build Automation** (UBA); GitHub Actions only starts them and reports back. Unity's build
  machines hold the Editor license — Unity Personal can't activate on GitHub-hosted or other hosted
  CI (offline activation is Enterprise/Industry only), which is why the Editor never runs in Actions.
  - Push to `stable` → EditMode + PlayMode tests, then a `StandaloneWindows64` playtest build.
  - `v*` tag (from `main`) → tests + release build.
  - PR labeled `cloud-ci` → tests + build of the PR head (and again on each push while labeled).
    Other PRs: run `unity test --affected --since origin/stable` locally before pushing.
  - Results (test counts, status, failure log tail) are in the run summary; download builds from
    Unity Dashboard → DevOps → Build Automation → Build History.
- UBA target: one Windows target (`UBA_TARGET`) with auto-build **off**, tests on with "fail build
  on test failure", max concurrent builds 1. The workflow queues runs per ref and never cancels a
  build mid-run; canceling the Actions run by hand cancels the UBA build.
- Budget: UBA free tier is 200 Windows minutes/month and the DevOps project locks when it's
  exceeded; the workflow checks `free-tier-status` before starting. Polling also uses GitHub
  Actions minutes for the length of each build.
- Secrets: `UNITY_SERVICE_ACCOUNT_ID`, `UNITY_SERVICE_ACCOUNT_SECRET` (service account
  `github-actions-gameci-workflows`, role **Automation User** on this project).
  Variables: `UBA_ORG_ID` (`2474071296604`, the org's genesisId), `UBA_PROJECT_ID`
  (`11dc2766-aaf6-41b9-a1de-cb0ab4a06bc2`, the Unity Cloud project with DevOps enabled),
  `UBA_TARGET` (`default-windows-desktop-64-bit`).
- Fork PRs never run it. Later options: Pro/Plus + GitHub-hosted runners, or a self-hosted runner
  (the Unity CLI `machine`-mode workflow; see the devkit's `unity-init` skill).
