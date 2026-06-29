# Detecting Unity project context

Run this before writing code in an unfamiliar Unity project. Prefer reading `CLAUDE.md` (it should pin these facts); fall back to detecting from project files, then offer to record what you found in `CLAUDE.md` so the next session skips this.

## Table of contents
- Unity version
- Render pipeline
- Input backend
- Assembly definitions
- Existing architecture

## Unity version

Read `ProjectSettings/ProjectVersion.txt`:

```
m_EditorVersion: 6000.0.23f1
```

`6000.x` = Unity 6. `2022.3.x` = 2022 LTS. Do not assume an API exists across versions — when unsure, confirm against the installed version's docs (or the `unity-editor-loop` reflection/console path) rather than from memory.

## Render pipeline

Grep `Packages/manifest.json`:

- `com.unity.render-pipelines.universal` → **URP**
- `com.unity.render-pipelines.high-definition` → **HDRP**
- neither → **Built-in** (legacy)

Why it matters: shaders and materials are pipeline-specific. A Built-in `Standard` material renders **magenta** in URP/HDRP. URP lit shader is `Universal Render Pipeline/Lit`; HDRP is `HDRP/Lit`. HLSL includes differ. Never write a Built-in shader into a URP project. Unity 6 URP enables Render Graph by default.

## Input backend

Check `ProjectSettings/ProjectSettings.asset` for `activeInputHandler` (0 = legacy only, 1 = Input System only, 2 = both), and whether `com.unity.inputsystem` is in `manifest.json`.

- Legacy: `Input.GetKey`, `Input.GetAxis` polling in `Update`.
- Input System: Input Action assets → generated C# or `PlayerInput` callbacks. Action-based, not polled.

Write to whichever is active. Never mix backends in one project.

## Assembly definitions

```
find Assets -name '*.asmdef'
```

Each `.asmdef` is a separately compiled assembly with explicit dependencies. New scripts belong to the assembly of their folder. Test assemblies need references to `UnityEngine.TestRunner`/`UnityEditor.TestRunner` plus the assemblies under test — adding tests often means editing an `.asmdef`'s `references` array (see the unity-testing skill).

## Existing architecture

Before applying any default, look for an established pattern:

- `com.svermeulen.extenject` / Zenject or `jp.hadashikick.vcontainer` / VContainer in `manifest.json` → the project uses **DI**. Use constructor injection and its conventions.
- Folders like `Presenters/`, `Views/`, `Models/` → MVC/MVP. Follow it.
- Existing `*EventChannelSO`, `*.asset` event objects → already on SO event channels. Extend that.

Conform to what exists. Only apply the SO + event-channel default on genuinely greenfield code.
