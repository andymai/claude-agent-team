---
name: unity-build
description: Run headless Unity builds and CI — batchmode player builds, Addressables content builds, and test/build pipelines (GameCI). Invoke deliberately with /unity-build; this never auto-runs because builds are long and side-effecting.
when_to_use: You explicitly want to produce a player build, set up Addressables build steps, or configure a CI pipeline (GitHub Actions / GameCI) for a Unity project.
disable-model-invocation: true
argument-hint: "[target] e.g. StandaloneLinux64 | StandaloneWindows64 | Android"
---

# Unity headless builds & CI

Builds are long, resource-heavy, and side-effecting, so this skill is **command-only** — you (the user) trigger `/unity-build`; Claude won't start one on its own. Parse the requested target from `$ARGUMENTS`. If unspecified, determine the project's active target by observation, not assumption: check the most recent `Editor.log`/build log for the last-built target, or read `ProjectSettings/EditorBuildSettings.asset` via Editor tooling; if still indeterminate, ask the user rather than guessing a platform.

## Headless player build

Unity builds via a static C# method invoked from the CLI. The project needs a build script under an `Editor/` folder:

```csharp
// Assets/Editor/BuildScript.cs
using UnityEditor;
public static class BuildScript
{
    public static void PerformBuild()
    {
        var scenes = System.Array.ConvertAll(
            EditorBuildSettings.scenes, s => s.path);
        BuildPipeline.BuildPlayer(new BuildPlayerOptions {
            scenes = scenes,
            locationPathName = System.Environment
                .GetEnvironmentVariable("BUILD_OUTPUT") ?? "Builds/game",
            // Uses whatever target the CLI's -buildTarget flag selected —
            // never hardcode a BuildTarget here or the requested platform is ignored.
            target = EditorUserBuildSettings.activeBuildTarget,
            options = BuildOptions.None,
        });
    }
}
```

Invoke headlessly (resolve `<unity-binary>` from `ProjectSettings/ProjectVersion.txt` + the Hub install dirs — see unity-editor-loop's CLI fallback; `Unity` is rarely on PATH):

```bash
<unity-binary> -batchmode -quit -projectPath <path> \
      -buildTarget StandaloneLinux64 \
      -executeMethod BuildScript.PerformBuild \
      -logFile <abs>/build.log -nographics
echo "exit: $?"            # non-zero = build failed
grep -nE 'error|Exception|BuildFailed' <abs>/build.log | tail -40
```

**Builds outlast shell timeouts.** A player build routinely runs longer than the Bash tool's cap, and a killed process is not a failed build. Run the build in the background (or with the maximum timeout) and poll `build.log` for progress. If the process was killed by a harness timeout rather than exiting on its own, say exactly that — do not report it as a build failure, and do not blindly relaunch: a half-written `Builds/` artifact plus a fresh build doubles the damage. Check the log tail to see where it stopped first.

Always read `build.log` — `BuildPipeline.BuildPlayer` can "succeed" the process while reporting a failed `BuildReport`. Check the report summary in the log, not just the exit code.

## Addressables

If the project uses Addressables, content is built separately from the player. Build the content (via `AddressableAssetSettings.BuildPlayerContent` from an editor method, or the Addressables menu through `Unity_RunCommand`) **before** the player build, and decide local vs remote hosting. Stale Addressables content is a common "works in Editor, broken in build" cause.

## CI (GameCI)

For GitHub Actions, **GameCI** wraps the batchmode test and build invocations:

- `game-ci/unity-test-runner` — runs EditMode/PlayMode tests, emits NUnit XML (pair with the **unity-testing** skill).
- `game-ci/unity-builder` — produces players per target.
- Requires a Unity license activation step and caching of `Library/` for speed.

Pin the Unity version in the workflow to match `ProjectSettings/ProjectVersion.txt`. Run tests before build; fail the pipeline on either.

## Before reporting success

A finished process is not a shippable build. Confirm all four, and quote the evidence for each in your report — the `echo "exit: $?"` line, the log's `BuildReport` summary line, and an `ls -la` of the artifact:

1. Exit code 0 (quoted, not assumed)
2. No `error`/`Exception`/`BuildFailed` lines in the log (state the grep you ran)
3. The `BuildReport` summary in the log says `Succeeded` — this is the one that catches "process exited 0 but the build failed"
4. The output artifact exists at the expected path with a plausible size (a 4 KB "player" is a failure)

State explicitly which target you built. If any check fails or couldn't be performed, the build is **not reportable as successful** — say which check failed and show the relevant log excerpt verbatim.

## Related skills

- **unity-testing** — gate builds behind passing tests.
- **unity-asset-safety** — ensure `.meta`/Addressables/version-control hygiene before building.
