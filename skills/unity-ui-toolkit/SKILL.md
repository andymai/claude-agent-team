---
name: unity-ui-toolkit
description: Build Unity UI with UI Toolkit — UXML structure, USS styling, data binding, and the runtime vs Editor UI split. Use when creating or editing .uxml or .uss files, building runtime HUDs/menus or custom Editor windows/inspectors with UI Toolkit (not uGUI).
when_to_use: Editing .uxml or .uss; building a UI Toolkit HUD, menu, custom Editor window, or custom inspector; questions about UXML/USS, UQuery, UIDocument, or data binding. (For legacy Canvas/uGUI UI, this skill does not apply.)
paths: "**/*.uxml,**/*.uss"
---

# Unity UI Toolkit (UXML / USS)

UI Toolkit is the modern, retained-mode UI system: structure in **UXML** (XML), styling in **USS** (CSS-like), queried and driven from C#. It powers both runtime UI and Editor tooling. First confirm the project actually uses UI Toolkit and not legacy uGUI Canvas — they don't mix well; follow whichever the project established.

## The three layers

- **UXML** — element hierarchy (`VisualElement`, `Label`, `Button`, `ListView`, etc.). Keep it structural; no inline styling beyond layout intent.
- **USS** — styling: layout (Flexbox model — `flex-direction`, `flex-grow`, `align-items`), colors, fonts. Selectors by type, `.class`, and `#name`. Reuse classes; avoid styling by name where a class fits.
- **C#** — load the tree, query elements with UQuery, wire behavior.

```csharp
public sealed class HUD : MonoBehaviour
{
    [SerializeField] private UIDocument document;   // runtime UI entry point
    private Label _score;

    private void OnEnable()
    {
        var root = document.rootVisualElement;
        _score = root.Q<Label>("score-label");        // UQuery by name
        root.Q<Button>("pause").clicked += OnPause;
    }

    public void SetScore(int value) => _score.text = value.ToString();
}
```

## Runtime vs Editor UI

- **Runtime UI** uses a `UIDocument` component referencing a Panel Settings asset and your UXML. Lives in the scene.
- **Editor UI** (custom windows, inspectors) builds the tree in `CreateGUI()` / `CreateInspectorGUI()` and lives under an `Editor/` folder/asmdef — never shipped at runtime (see unity-csharp Editor-code rule).

Same UXML/USS authoring model; different entry point and assembly. Keep them separate.

## Data binding

Unity 6 supports runtime data binding (`SerializedObject` bindings in the Editor; binding paths and `INotifyBindablePropertyChanged` at runtime). Prefer binding over manually pushing values every frame. For lists, use `ListView`/`MultiColumnListView` with `makeItem`/`bindItem` and virtualization rather than instantiating elements per row.

## Performance notes

- Cache UQuery results in `OnEnable`; don't `Q<>()` every frame (it walks the tree — same spirit as the GetComponent rule).
- Toggle visibility with `display: none` / `DisplayStyle` rather than rebuilding the tree.
- Minimize per-frame USS changes; style recalculation isn't free.

## Related skills

- **unity-csharp** — Editor-vs-runtime assembly rules, lifecycle, the no-per-frame-query rule.
- **unity-asset-safety** — `.uxml`/`.uss` are text and safe to edit, but their `.meta` files still pair (and any referencing `.asset`/scene wiring goes through the Editor).
