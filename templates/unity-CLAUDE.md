<!--
  Unity project CLAUDE.md template (from claude-agent-team Unity skills).
  Copy this to your Unity project root as CLAUDE.md and fill in the < > placeholders.
  Pinning these facts once stops every session from re-detecting them and prevents
  version/pipeline/input mismatches. Delete this comment after filling in.
-->

# <Project Name>

Unity game project. The Unity skills (`unity-csharp`, `unity-editor-loop`, `unity-testing`,
`unity-asset-safety`, `unity-performance`, `unity-ui-toolkit`, `unity-build`) apply here.

## Project facts (verify against the repo, then keep current)

- **Unity version:** <6000.0.x>  — see `ProjectSettings/ProjectVersion.txt`
- **Render pipeline:** <URP | HDRP | Built-in>
- **Input backend:** <Input System | legacy | Both>
- **UI system:** <UI Toolkit | uGUI/Canvas>
- **Architecture:** <ScriptableObject + event channels | VContainer DI | MVC | ...>
- **Assembly layout:** <one root asmdef | per-feature asmdefs under Assets/...>
- **Test location:** <Assets/Tests with EditMode/PlayMode asmdefs>

## Conventions

- Namespace: `<Studio.Game>`
- Folder structure: `Assets/{Scripts,Prefabs,Scenes,Settings,Art,Tests}`; Editor-only code under `Editor/`.
- Data lives in ScriptableObjects, not literals in MonoBehaviours. <adjust if using DI/MVC>

## Hard rules for agents

- **Console is ground truth.** After editing C#, recompile and read the console before claiming done — a file write is not a compile.
- **Do not hand-edit `.unity` scenes or `.prefab` files as text.** Route hierarchy/prefab/Inspector changes through the Editor (or MCP Editor tooling), or surface them to a human.
- **Never change a `.meta` GUID.** Move/rename/delete an asset and its `.meta` together; commit them together.
- **No allocations or component lookups in `Update`/`FixedUpdate`/`LateUpdate`.** Cache in `Awake`/`Start`; pool spawned objects.
- **Match the active render pipeline and input backend** above — don't write Built-in shaders into a URP project or mix input backends.
- **Tests passing ≠ game works.** Pair tests with a visual capture check before declaring a gameplay change done.

## Commands

- Run EditMode tests: `Unity -batchmode -runTests -projectPath . -testPlatform EditMode -testResults results.xml -logFile test.log`
- Build: `/unity-build <target>`  (or `Unity -batchmode -quit -executeMethod BuildScript.PerformBuild ...`)
