---
name: unity-editor-loop
description: Drive the live Unity Editor as a feedback loop — recompile after edits, read the console for compile errors and runtime exceptions, capture the Game/Scene view to verify visually, and debug runtime issues. Use after editing Unity scripts, when the game misbehaves or throws, or when you need to see what the Editor is actually rendering.
when_to_use: Just edited Unity C# and need to confirm it compiles; the game throws an exception or behaves wrong; need to visually verify a scene, prefab, or UI looks right; debugging a Unity runtime issue; want to enter or exit Play mode.
---

# Unity Editor feedback loop (via MCP, with CLI fallback)

A file write is **not** a successful compile — Unity compiles asynchronously, and gameplay bugs hide behind green unit tests. The console and the rendered view are ground truth. This skill is the loop that closes that gap.

This environment exposes a curated `unity-mcp` server (capture- and command-oriented). Tool names below are friendly; the fully-qualified MCP names are `mcp__unity-mcp__<Name>`. **If the server is not connected, degrade to the CLI fallback** at the bottom.

## The core loop (run after every change)

1. **Recompile.** Trigger a refresh/recompile so Unity picks up file changes — `Unity_RunCommand` to invoke the equivalent of *Assets → Refresh* (or just let the Editor recompile on focus).
2. **Read the console.** `Unity_GetConsoleLogs` — scan for compile errors first, then warnings, then runtime exceptions. **Do not proceed while compile errors exist.** Fix and re-run from step 1.
3. **Verify visually when behavior is visual.** Capture before claiming success:
   - `Unity_Camera_Capture` — what the player sees (Game view).
   - `Unity_SceneView_Capture2DScene` — the Scene view for 2D framing.
   - `Unity_SceneView_CaptureMultiAngleSceneView` — multiple angles for 3D layout/scale checks.
4. **Iterate.** Only declare done when the console is clean *and* (for visual changes) the capture matches intent.

> The #1 Unity-agent failure is "tests pass but the game is unplayable." A clean compile and green tests are necessary, not sufficient — capture and look.

**Gates, spelled out:** you may not move from step 2 to step 3 while any `error CS` line is present; you may not claim visual success without a capture taken *after* the change compiled clean; and every claim in your final report must quote its evidence — the console line, the capture you took, or the log excerpt. "Recompiled and it looks fine" without a quoted console read and a capture is a fabricated verification.

**Circuit breaker:** if the *same* compile error survives three fix attempts, stop editing. Re-read the full error including its file:line (not your memory of it), open that exact location, and check the usual suspects in order: wrong/missing asmdef reference, API that doesn't exist in this Unity version (see unity-csharp rule 8), editor-only code referenced from runtime, stale generated code needing a refresh. If it still stands, report blocking state — the error text verbatim, what you tried, what you need — rather than a fourth guess.

## Debugging runtime issues

1. **Reproduce.** Get the project into the failing state (enter Play mode via `Unity_RunCommand` if the bug is runtime).
2. **Read the exception.** `Unity_GetConsoleLogs` — capture the full stack trace, not just the message. Note the file:line and the object/component involved.
3. **Form one hypothesis at a time.** Common Unity causes: null reference from an unassigned `[SerializeField]` in the Inspector; missing component; lifecycle ordering (`Awake` vs `Start`); event subscription never removed; wrong render pipeline material (magenta = pipeline mismatch, see unity-csharp's `reference/detect-project.md`).
4. **Capture the scene** if the symptom is visual/positional — a multi-angle capture often reveals off-screen, zero-scaled, or mis-parented objects that a log won't show.
5. **Fix in C#, then re-run the core loop.** Confirm the exception is gone *and* nothing new appeared.

Note: inspector-level wiring (unassigned references, component setup) often can't be fixed by editing `.cs` alone. If the fix is in scene/prefab data, see **unity-asset-safety** — route it through Editor tooling or surface it to the user rather than hand-editing YAML.

## Generative assets (optional)

If a missing placeholder mesh blocks progress: `Unity_AssetGeneration_GetModels` lists available generative models; `Unity_AssetGeneration_GenerateAsset` produces one. Treat generated assets as placeholders and confirm import (and that a `.meta` was created — see unity-asset-safety).

## CLI fallback (no MCP server connected)

When `unity-mcp` is unavailable, you lose live capture but can still close the compile loop headlessly.

`Unity` is rarely on PATH — resolve the binary first: read the pinned version from `ProjectSettings/ProjectVersion.txt`, then look in the Hub install locations (`~/Unity/Hub/Editor/<version>/Editor/Unity` on Linux, `/Applications/Unity/Hub/Editor/<version>/Unity.app/Contents/MacOS/Unity` on macOS, `C:\Program Files\Unity\Hub\Editor\<version>\Editor\Unity.exe` on Windows) and glob for the version dir. The binary version must match the project's — a different version will rewrite `ProjectVersion.txt` and reimport the Library.

```bash
# Compile + surface errors via a batchmode no-op that forces a script compile
<unity-binary> -batchmode -quit -projectPath <path> \
      -logFile <abs>/unity-compile.log -nographics
# Then read the log for "error CS" lines:
grep -nE 'error CS[0-9]+' <abs>/unity-compile.log
```

**If neither channel exists** — no MCP server *and* no matching Unity binary found — the compile gate cannot be closed in this environment. Stop editing, report compile status as **UNVERIFIED**, and hand the user the exact batchmode command (with the resolved paths filled in) to run themselves. Do not keep iterating on code you cannot compile, and never report "compiles clean" without having seen a console or log.

For runtime/visual verification without MCP, hand off to the user to run the Editor, or rely on the **unity-testing** skill's PlayMode tests. Be explicit in your report that visual verification was **not** performed when the server was absent — never imply you saw the result.

## Related skills

- **unity-csharp** — the coding rules feeding this loop.
- **unity-testing** — automated EditMode/PlayMode coverage to pair with visual capture.
- **unity-asset-safety** — when the fix lives in scene/prefab/meta data, not C#.
