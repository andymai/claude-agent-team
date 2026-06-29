---
name: unity-csharp
description: Write idiomatic, performance-safe Unity 6 C# — MonoBehaviour lifecycle, ScriptableObject + event-channel architecture, serialization, the Input System, and assembly definitions. Use when writing or editing Unity C# scripts (.cs), adding gameplay systems, components, or ScriptableObjects, or wiring data and events in a Unity project.
when_to_use: Editing or creating .cs files in a Unity project; adding a MonoBehaviour, ScriptableObject, system, or manager; questions about Unity serialization, [SerializeField], Input System, asmdef boundaries, or how to structure gameplay code.
paths: "**/*.cs"
---

# Unity C# & Architecture (Unity 6, URP)

Write Unity C# that compiles clean, allocates nothing in hot paths, and decouples data from logic. This skill is the standing playbook for C# work; load the reference files below as needed.

## Step 0 — Detect project context first (non-negotiable)

Never write Unity code blind. Before touching `.cs`, establish the project's reality. Read `CLAUDE.md` first (it should pin these); if absent or silent, detect them and offer to record them. See `reference/detect-project.md` for the exact files to read. You must know:

- **Unity version** — `ProjectSettings/ProjectVersion.txt`. APIs differ by version; do not trust memory for API existence.
- **Render pipeline** — Built-in / URP / HDRP (grep `Packages/manifest.json`). Shaders and some camera/light APIs are pipeline-specific.
- **Input backend** — legacy `Input.GetKey` vs the Input System package (`com.unity.inputsystem`), or Both. Write to whichever the project uses; never mix.
- **Assembly boundaries** — existing `.asmdef` files. New code (and tests) must respect and reference the right assemblies.
- **Existing architecture** — if the project already uses DI (VContainer/Zenject), MVC, or an established pattern, **conform to it.** The default below applies only to greenfield code.

## Hard rules (always apply, regardless of architecture)

These are correctness and performance, not taste. Violating them is a bug.

1. **No allocations or lookups in `Update`/`FixedUpdate`/`LateUpdate`.** Cache `GetComponent<T>()`, `Camera.main`, and `GameObject.Find` results in `Awake`/`Start`. No per-frame `new`, LINQ, boxing, or string concatenation in hot paths.
2. **Generic `GetComponent<T>()` only** — never the string overload (slower, allocates).
3. **Serialize deliberately.** Only `public` or `[SerializeField] private` fields serialize. Properties, `static`, `const`, and `readonly` do not. Renaming a serialized field orphans its data unless you add `[FormerlySerializedAs("old")]`. See `reference/serialization-and-input.md`.
4. **Pool frequently spawned objects** (bullets, VFX, enemies) via `UnityEngine.Pool.ObjectPool<T>` instead of `Instantiate`/`Destroy` churn.
5. **Editor-only code lives in an `Editor/` folder or Editor-constrained asmdef** and is never referenced by runtime code.
6. **Respect the MonoBehaviour lifecycle:** `Awake` (self-init) → `OnEnable` → `Start` (cross-object refs) → `Update`/`FixedUpdate`/`LateUpdate` → `OnDisable`/`OnDestroy`. Never assume `Awake` order across objects; resolve cross-object references in `Start`.
7. **Console is ground truth.** A successful file write is not a successful compile (Unity compiles asynchronously). After edits, drive the `unity-editor-loop` skill to recompile and read the console before declaring done.

## Default architecture (greenfield only): ScriptableObject + event channels

When there is no established pattern to conform to, default to Unity-native, dependency-free decoupling. Full guidance and code templates in `reference/architecture.md`. In short:

- **Data → ScriptableObjects.** Item stats, configs, tunables live in SOs, not hard-coded in MonoBehaviours.
- **Decouple via SO event channels.** A `GameEventChannelSO` raises; listeners subscribe. No singletons reaching into each other, no `GameObject.Find` wiring.
- **Logic stays testable.** Keep gameplay rules in plain C# / SO methods callable without a running scene, so the `unity-testing` skill can cover them in EditMode.

This is a default, not a mandate. If the project standardized on DI or MVC, follow that instead.

## Reference files

- `reference/detect-project.md` — exact files to read to detect version, pipeline, input backend, asmdefs.
- `reference/architecture.md` — ScriptableObject + event-channel patterns with code templates; when to deviate.
- `reference/serialization-and-input.md` — serialization rules, `[SerializeField]`/`[FormerlySerializedAs]`, Input System action-asset setup.

## Related skills

- After editing: **unity-editor-loop** (recompile + read console + visually verify).
- For optimization once something is measurably slow: **unity-performance**.
- Before moving/renaming `.cs` files or touching scenes/prefabs: **unity-asset-safety**.
