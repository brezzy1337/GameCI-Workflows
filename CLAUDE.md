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

- Workflow: `.github/workflows/unity.yml` (Unity CLI, not GameCI).
  - PR into `stable` → EditMode + PlayMode tests (`Test (EditMode + PlayMode)` check).
  - Push to `stable` → tests, then a `StandaloneWindows64` playtest build (artifact kept 14 days).
  - `v*` tag → tests, then the release build (kept 90 days).
- Runners: self-hosted on team members' Windows PCs, labels `[self-hosted, windows, x64, unity]`,
  running as the owner's account. The workflow never installs anything on them. It verifies CLI
  `1.0.0-beta.11` and Editor `6000.6.3f1` are present and fails with the fix command if not.
- License mode `machine`: each runner PC's own Unity Personal license; CI never returns it.
- `projectPath`: `.` · Secrets: `UNITY_SERVICE_ACCOUNT_ID`, `UNITY_SERVICE_ACCOUNT_SECRET`.
- Fork PRs are skipped; this repo must stay private while runners are personal PCs.
