# Glass Table Design — Spec

**Date:** 2026-04-03
**Scope:** Only glass themes (`dark-glass`, `light-glass-warm`). Default themes are not touched.
**Components:** Table rows, table header (`th`), vertical dividers variant, resize/drag handle affordances.

---

## 1. Overview

The table adopts a **floating rows** pattern: each `<tr>` appears as an individual pill-shaped card floating above the background. This mirrors the glass card language used in forms, adapted for dense tabular data.

Implementation is CSS-only via scoped overrides in `src/styles/style.scss` under the existing `[data-theme-style='dark-glass']` / `[data-theme-style='light-glass']` selectors. No Vue component logic changes.

---

## 2. Shared principles (both themes)

| Property | Value |
|---|---|
| `border-collapse` | `separate` |
| `border-spacing` | `0 6px` (6px vertical gap between rows) |
| Row `border-radius` | `14px` (first-child left corners, last-child right corners) |
| Header font | `Space Grotesk`, 9.5px, 700 weight, uppercase, 0.12em letter-spacing |
| Header `border` | none (floats above, no bottom line) |
| Amount chip | `border-radius: 999px`, accent-coloured bg + border |
| Secondary text (id, date) | muted colour, 12px |
| Edit icon cell | 28×28px, border-radius 8px, subtle bg + border |

### Header interactivity affordances

- **Drag grip:** three horizontal lines (⠿), appear on `th:hover`, opacity transitions `0→1`. Signals column is draggable. No JS needed in CSS spec — the existing drag mechanism applies.
- **Resize handle:** 3px wide bar on the right edge of each `th`, appears on `th:hover`. Uses `cursor: col-resize`. Colour matches accent at 35% opacity.

### Vertical dividers (opt-in via existing setting)

When the user enables vertical dividers, `td + td` gets a `border-left`. The divider colour is very subtle — does not conflict with the floating-row borders.

---

## 3. Dark Glass

### CSS variables / tokens used
```css
--accent: #59d6cf;
--muted:  #95a7b6;
--ink:    #e7ecef;
```

### Table background
The table sits directly on the `#app` gradient background — no separate wrapper background needed. The `root-wrapper` already has the glass panel treatment.

### Header `th`
```css
font-size: 9.5px;
font-weight: 700;
letter-spacing: 0.12em;
text-transform: uppercase;
color: rgba(89, 214, 207, 0.52);   /* --accent at 52% */
background: transparent;
border: none;
font-family: 'Space Grotesk', sans-serif;
padding: 4px 14px 10px;
position: relative;
```

### Row `td` (default)
```css
padding: 11px 14px;
background: rgba(255, 255, 255, 0.045);
border-top: 1px solid rgba(255, 255, 255, 0.055);
border-bottom: 1px solid rgba(255, 255, 255, 0.055);
color: #e7ecef;
font-size: 13px;

/* first-child */
border-left: 1px solid rgba(255, 255, 255, 0.055);
border-radius: 14px 0 0 14px;

/* last-child */
border-right: 1px solid rgba(255, 255, 255, 0.055);
border-radius: 0 14px 14px 0;
```

### Row hover
```css
background: rgba(89, 214, 207, 0.075);
border-color: rgba(89, 214, 207, 0.17);
```

### Selected row (`tr.selected td`)
```css
background: rgba(89, 214, 207, 0.09);
border-color: rgba(89, 214, 207, 0.20);
```

### Amount chip
```css
display: inline-block;
padding: 3px 11px;
border-radius: 999px;
background: rgba(89, 214, 207, 0.12);
border: 1px solid rgba(89, 214, 207, 0.26);
color: #59d6cf;
font-weight: 700;
font-size: 12px;
```

### Muted text (id, date columns)
```css
color: rgba(149, 167, 182, 0.6);
font-size: 12px;
```

### Edit icon cell
```css
width: 28px; height: 28px; border-radius: 8px;
background: rgba(255, 255, 255, 0.05);
border: 1px solid rgba(255, 255, 255, 0.08);
color: rgba(149, 167, 182, 0.55);
```

### Vertical dividers (`.with-vlines` / when setting is on)
```css
td + td {
  border-left: 1px solid rgba(255, 255, 255, 0.07);
}
/* on hover: */
tr:hover td + td {
  border-left-color: rgba(89, 214, 207, 0.13);
}
```

### Drag grip
```css
/* appears on th:hover */
.drag-grip { opacity: 0; transition: opacity 0.15s; }
th:hover .drag-grip { opacity: 1; }
.drag-grip-line {
  display: block; width: 12px; height: 1.5px;
  background: rgba(89, 214, 207, 0.45); border-radius: 1px;
}
```

### Resize handle
```css
position: absolute; right: 0; top: 20%; height: 60%;
width: 3px; border-radius: 2px;
background: rgba(89, 214, 207, 0.0);
transition: background 0.15s;
cursor: col-resize;
/* on th:hover: */
background: rgba(89, 214, 207, 0.35);
```

---

## 4. Light Glass Warm

### CSS variables / tokens used
```css
--accent:   #2185a0;
--sea-deep: #1a5f7a;
--muted:    #6f6a62;
--ink:      #1f1f1f;
```

### Header `th`
```css
color: #2185a0;
background: transparent;
border: none;
font-family: 'Space Grotesk', sans-serif;
font-size: 9.5px; font-weight: 700;
letter-spacing: 0.12em; text-transform: uppercase;
padding: 4px 14px 10px;
position: relative;
```

### Row `td` (default)
```css
padding: 11px 14px;
background: rgba(255, 255, 255, 0.55);
border-top: 1px solid rgba(196, 182, 163, 0.22);
border-bottom: 1px solid rgba(196, 182, 163, 0.22);
color: #1f1f1f;
font-size: 13px;

/* first-child */
border-left: 1px solid rgba(196, 182, 163, 0.22);
border-radius: 14px 0 0 14px;

/* last-child */
border-right: 1px solid rgba(196, 182, 163, 0.22);
border-radius: 0 14px 14px 0;
```

### Row hover
```css
background: rgba(255, 255, 255, 0.85);
border-color: rgba(33, 133, 160, 0.22);
box-shadow: 0 2px 12px rgba(28, 23, 15, 0.07);
```

### Selected row
```css
background: rgba(33, 133, 160, 0.08);
border-color: rgba(33, 133, 160, 0.22);
```

### Amount chip
```css
padding: 3px 11px; border-radius: 999px;
background: rgba(33, 133, 160, 0.10);
border: 1px solid rgba(33, 133, 160, 0.22);
color: #1a5f7a; font-weight: 700; font-size: 12px;
```

### Muted text
```css
color: rgba(111, 106, 98, 0.65);
font-size: 12px;
```

### Edit icon cell
```css
width: 28px; height: 28px; border-radius: 8px;
background: rgba(255, 255, 255, 0.65);
border: 1px solid rgba(196, 182, 163, 0.3);
color: rgba(111, 106, 98, 0.6);
```

### Vertical dividers
```css
td + td {
  border-left: 1px solid rgba(196, 182, 163, 0.18);
}
tr:hover td + td {
  border-left-color: rgba(33, 133, 160, 0.15);
}
```

### Drag grip
```css
th:hover .drag-grip { opacity: 1; }
.drag-grip-line { background: rgba(33, 133, 160, 0.50); }
```

### Resize handle
```css
/* on th:hover: */
background: rgba(33, 133, 160, 0.35);
cursor: col-resize;
```

---

## 5. Where to implement

All overrides go in `src/styles/style.scss` under the existing glass theme selectors:

```
#app[data-theme-style='dark-glass'] .custom-table ...
#app[data-theme-style='light-glass'] .custom-table ...
```

The drag grip and resize handle are rendered inside `th` in `Table.vue` (the column caption area already exists). The grip needs a small wrapper `div` added to the caption slot, styled via scoped glass SCSS. The resize handle is a pseudo-element `::after` on `th` — no JS, only CSS affordance (actual resize logic already exists).

`border-collapse: separate` and `border-spacing` override must be applied to `.custom-table` scoped to glass themes, since the default uses `collapse`.

### Amount chip

The `amount` chip style (pill shape, accent colour) applies to cells whose column has `cell_variant = amount` attribute, or can be driven via the existing `option` class when the field type has an enum/colour variant. No new attribute needed — this is a CSS class applied by existing logic.

---

## 6. Out of scope

- Default (non-glass) themes — no changes
- Mobile-specific layout — follows CSS variables, no separate treatment
- Pagination footer row — follows the same `td` border treatment automatically
- Sticky/fixed columns — existing `backdrop-filter` on fixed cells is preserved; border-radius only applies to first/last visible cell in the row

---

## 7. Open questions

None — design approved.
