---
name: unity-editor-loop
description: Drive the live Unity Editor as a feedback loop — recompile after edits, read the console for compile errors and runtime exceptions, capture the Game/Scene view to verify visually, and debug runtime issues. Use after editing Unity scripts, when the game misbehaves or throws, or when you need to see what the Editor is actually rendering.
when_to_use: Just edited Unity C# and need to confirm it compiles; the game throws an exception or behaves wrong; need to visually verify a scene, prefab, or UI looks right; debugging a Unity runtime issue; want to enter or exit Play mode.
allowed-tools: Bash, Read, Grep, Glob
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

## Debugging runtime issues

1. **Reproduce.** Get the project into the failing state (enter Play mode via `Unity_RunCommand` if the bug is runtime).
2. **Read the exception.** `Unity_GetConsoleLogs` — capture the full stack trace, not just the message. Note the file:line and the object/component involved.
3. **Form one hypothesis at a time.** Common Unity causes: null reference from an unassigned `[SerializeField]` in the Inspector; missing component; lifecycle ordering (`Awake` vs `Start`); event subscription never removed; wrong render pipeline material (magenta = pipeline mismatch, see unity-asset-safety).
4. **Capture the scene** if the symptom is visual/positional — a multi-angle capture often reveals off-screen, zero-scaled, or mis-parented objects that a log won't show.
5. **Fix in C#, then re-run the core loop.** Confirm the exception is gone *and* nothing new appeared.

Note: inspector-level wiring (unassigned references, component setup) often can't be fixed by editing `.cs` alone. If the fix is in scene/prefab data, see **unity-asset-safety** — route it through Editor tooling or surface it to the user rather than hand-editing YAML.

## Generative assets (optional)

If a missing placeholder mesh blocks progress: `Unity_AssetGeneration_GetModels` lists available generative models; `Unity_AssetGeneration_GenerateAsset` produces one. Treat generated assets as placeholders and confirm import (and that a `.meta` was created — see unity-asset-safety).

## CLI fallback (no MCP server connected)

When `unity-mcp` is unavailable, you lose live capture but can still close the compile loop headlessly:

```bash
# Compile + surface errors via a batchmode no-op that forces a script compile
Unity -batchmode -quit -projectPath <path> \
      -logFile <abs>/unity-compile.log -nographics
# Then read the log for "error CS" lines:
grep -nE 'error CS[0-9]+' <abs>/unity-compile.log
```

For runtime/visual verification without MCP, hand off to the user to run the Editor, or rely on the **unity-testing** skill's PlayMode tests. Be explicit in your report that visual verification was **not** performed when the server was absent — never imply you saw the result.

## Related skills

- **unity-csharp** — the coding rules feeding this loop.
- **unity-testing** — automated EditMode/PlayMode coverage to pair with visual capture.
- **unity-asset-safety** — when the fix lives in scene/prefab/meta data, not C#.
