---
name: unity-build
description: Run headless Unity builds and CI — batchmode player builds, Addressables content builds, and test/build pipelines (GameCI). Invoke deliberately with /unity-build; this never auto-runs because builds are long and side-effecting.
when_to_use: You explicitly want to produce a player build, set up Addressables build steps, or configure a CI pipeline (GitHub Actions / GameCI) for a Unity project.
disable-model-invocation: true
argument-hint: "[target] e.g. StandaloneLinux64 | StandaloneWindows64 | Android"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Unity headless builds & CI

Builds are long, resource-heavy, and side-effecting, so this skill is **command-only** — you (the user) trigger `/unity-build`; Claude won't start one on its own. Parse the requested target from `$ARGUMENTS` (default to the project's main platform if unspecified).

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
            target = BuildTarget.StandaloneLinux64,
            options = BuildOptions.None,
        });
    }
}
```

Invoke headlessly:

```bash
Unity -batchmode -quit -projectPath <path> \
      -executeMethod BuildScript.PerformBuild \
      -logFile <abs>/build.log -nographics
echo "exit: $?"            # non-zero = build failed
grep -nE 'error|Exception|BuildFailed' <abs>/build.log | tail -40
```

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

A finished process is not a shippable build. Confirm: exit code 0, no errors in the log, the `BuildReport` summary says `Succeeded`, and the output artifact exists at the expected path. State explicitly which target you built.

## Related skills

- **unity-testing** — gate builds behind passing tests.
- **unity-asset-safety** — ensure `.meta`/Addressables/version-control hygiene before building.
