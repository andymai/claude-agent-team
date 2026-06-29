# Serialization & Input System

## Table of contents
- Serialization rules
- Renaming serialized fields
- Polymorphic serialization
- Input System setup

## Serialization rules

Unity serializes a field only if **all** hold: it is `public` OR has `[SerializeField]`; it is not `static`, `const`, or `readonly`; and its type is serializable (primitives, `string`, `enum`, Unity types like `Vector3`/`Color`, `UnityEngine.Object` references, or `[Serializable]` plain classes/structs).

Not serialized: properties (even auto-properties), `static`/`const`/`readonly` fields, `Dictionary<,>` (use parallel lists or a serializable wrapper), and bare interface/abstract fields (see polymorphic section).

```csharp
public sealed class Health : MonoBehaviour
{
    [SerializeField] private int maxHealth = 100;   // serialized, hidden from other classes
    public int Current { get; private set; }         // NOT serialized (property)
    private float regenTimer;                          // NOT serialized (private, no attribute)
}
```

Use `[SerializeField] private` over `public` for Inspector-editable fields you don't want other code mutating. Use `[field: SerializeField]` to serialize an auto-property's backing field.

## Renaming serialized fields

Renaming a serialized field **orphans its saved data** in every scene/prefab/asset that used it — the value silently resets. Preserve it:

```csharp
[FormerlySerializedAs("hp")]   // requires: using UnityEngine.Serialization;
[SerializeField] private int maxHealth = 100;
```

This is a frequent silent-data-loss bug when an agent renames fields. Always add `[FormerlySerializedAs]` when renaming a serialized field that may already hold authored data.

## Polymorphic serialization

A field typed as an interface or abstract base won't serialize by default. Use `[SerializeReference]` for managed-reference polymorphism:

```csharp
[SerializeReference] private IAbility ability;
```

Note `[SerializeReference]` has its own gotchas (no shared references, migration caveats) — prefer concrete SO references where possible.

## Input System setup

If the project uses the Input System package (`com.unity.inputsystem`):

- Define an **Input Actions asset** (`.inputactions`) with action maps and actions; enable "Generate C# Class" for a typed wrapper, or use `PlayerInput` with Unity Events / `SendMessages`.
- Read input via callbacks (`context.performed`), not by polling `Input.GetKey` in `Update`.
- Enable/disable action maps with the object lifecycle (`OnEnable`/`OnDisable`) to avoid stale callbacks.

```csharp
public sealed class PlayerController : MonoBehaviour
{
    private InputAction moveAction;

    private void OnEnable()  => moveAction?.Enable();
    private void OnDisable() => moveAction?.Disable();

    private void Update()
    {
        Vector2 move = moveAction.ReadValue<Vector2>();
        // apply movement
    }
}
```

If the project is on the **legacy** backend, use `Input.GetAxis`/`Input.GetKey` instead — but confirm the active backend first (`detect-project.md`). Never mix the two.
