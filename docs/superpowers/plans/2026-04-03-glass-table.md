# Glass Table Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply floating-rows glass design to the table component for `dark-glass` and `light-glass` themes without touching default themes or Vue component logic.

**Architecture:** All changes are pure CSS overrides appended to `src/styles/style.scss` under existing `[data-theme-style='dark-glass']` / `[data-theme-style='light-glass']` selectors. The table uses `border-collapse: separate` + `border-spacing` for the floating-row effect. Row pill shape is achieved via `border-radius` on first/last `td` in each `tr`. Header affordances (drag grip visibility, resize handle colour) are CSS-only — the underlying JS drag/resize logic already exists in `Table.vue`.

**Tech Stack:** SCSS, CSS custom properties, existing glass theme tokens (`--accent`, `--muted`, `--ink`, `--line`, `--surface`)

---

## File map

| File | Action | What changes |
|---|---|---|
| `src/styles/style.scss` | Modify | Append glass table overrides at the end, before `@supports` block |

No Vue components need to change. No new files.

---

## Task 1: Create a new git branch

**Files:**
- No file changes

- [ ] **Step 1: Create and switch to new branch**

```bash
git -C /Users/vientooscuro/SyncFolder/ozma checkout -b feat/glass-table-design
```

Expected output: `Switched to a new branch 'feat/glass-table-design'`

---

## Task 2: Override `border-collapse` and `border-spacing` for glass themes

The default table uses `border-collapse: collapse`. Floating rows require `separate` + `border-spacing`.

**Files:**
- Modify: `src/styles/style.scss` — find and update existing `.custom-table` glass selector (around line 984)

- [ ] **Step 1: Locate the existing glass `.custom-table` rule**

Find this block in `src/styles/style.scss`:
```scss
#app[data-theme-style='light-glass'] .custom-table,
#app[data-theme-style='dark-glass'] .custom-table {
  background: transparent;
}
```

- [ ] **Step 2: Add `border-collapse` and `border-spacing`**

Replace that block with:
```scss
#app[data-theme-style='light-glass'] .custom-table,
#app[data-theme-style='dark-glass'] .custom-table {
  background: transparent;
  border-collapse: separate;
  border-spacing: 0 6px;
}
```

- [ ] **Step 3: Verify no existing test breaks**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

Expected: build succeeds (no SCSS errors).

- [ ] **Step 4: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): switch to border-separate with 6px row gap"
```

---

## Task 3: Floating row pill shape — dark-glass

Make each `tbody tr` look like a floating pill card in dark-glass.

**Files:**
- Modify: `src/styles/style.scss` — append after the last glass block (before `@supports not` block)

- [ ] **Step 1: Append dark-glass row styles**

Find the comment `@supports not (backdrop-filter: blur(1px))` near the end of `style.scss`. Insert the following block **immediately before** it:

```scss
/* ── Glass table: floating rows ── */

#app[data-theme-style='dark-glass'] .custom-table tbody tr td {
  background: rgba(255, 255, 255, 0.045);
  border-top: 1px solid rgba(255, 255, 255, 0.055);
  border-bottom: 1px solid rgba(255, 255, 255, 0.055);
  border-left: none;
  border-right: none;
  color: #e7ecef;
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr td:first-child {
  border-left: 1px solid rgba(255, 255, 255, 0.055);
  border-radius: 14px 0 0 14px;
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr td:last-child {
  border-right: 1px solid rgba(255, 255, 255, 0.055);
  border-radius: 0 14px 14px 0;
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr:hover td {
  background: rgba(89, 214, 207, 0.075);
  border-top-color: rgba(89, 214, 207, 0.17);
  border-bottom-color: rgba(89, 214, 207, 0.17);
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr:hover td:first-child {
  border-left-color: rgba(89, 214, 207, 0.17);
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr:hover td:last-child {
  border-right-color: rgba(89, 214, 207, 0.17);
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr.selected td,
#app[data-theme-style='dark-glass'] .custom-table tbody tr.table-tr.selected td {
  background: rgba(89, 214, 207, 0.09);
  border-top-color: rgba(89, 214, 207, 0.20);
  border-bottom-color: rgba(89, 214, 207, 0.20);
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr.selected td:first-child,
#app[data-theme-style='dark-glass'] .custom-table tbody tr.table-tr.selected td:first-child {
  border-left-color: rgba(89, 214, 207, 0.20);
}

#app[data-theme-style='dark-glass'] .custom-table tbody tr.selected td:last-child,
#app[data-theme-style='dark-glass'] .custom-table tbody tr.table-tr.selected td:last-child {
  border-right-color: rgba(89, 214, 207, 0.20);
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): dark-glass floating row pill shape"
```

---

## Task 4: Floating row pill shape — light-glass

**Files:**
- Modify: `src/styles/style.scss` — append after Task 3 block

- [ ] **Step 1: Append light-glass row styles**

```scss
#app[data-theme-style='light-glass'] .custom-table tbody tr td {
  background: rgba(255, 255, 255, 0.55);
  border-top: 1px solid rgba(196, 182, 163, 0.22);
  border-bottom: 1px solid rgba(196, 182, 163, 0.22);
  border-left: none;
  border-right: none;
  color: #1f1f1f;
}

#app[data-theme-style='light-glass'] .custom-table tbody tr td:first-child {
  border-left: 1px solid rgba(196, 182, 163, 0.22);
  border-radius: 14px 0 0 14px;
}

#app[data-theme-style='light-glass'] .custom-table tbody tr td:last-child {
  border-right: 1px solid rgba(196, 182, 163, 0.22);
  border-radius: 0 14px 14px 0;
}

#app[data-theme-style='light-glass'] .custom-table tbody tr:hover td {
  background: rgba(255, 255, 255, 0.85);
  border-top-color: rgba(33, 133, 160, 0.22);
  border-bottom-color: rgba(33, 133, 160, 0.22);
  box-shadow: 0 2px 12px rgba(28, 23, 15, 0.07);
}

#app[data-theme-style='light-glass'] .custom-table tbody tr:hover td:first-child {
  border-left-color: rgba(33, 133, 160, 0.22);
}

#app[data-theme-style='light-glass'] .custom-table tbody tr:hover td:last-child {
  border-right-color: rgba(33, 133, 160, 0.22);
}

#app[data-theme-style='light-glass'] .custom-table tbody tr.selected td,
#app[data-theme-style='light-glass'] .custom-table tbody tr.table-tr.selected td {
  background: rgba(33, 133, 160, 0.08);
  border-top-color: rgba(33, 133, 160, 0.22);
  border-bottom-color: rgba(33, 133, 160, 0.22);
}

#app[data-theme-style='light-glass'] .custom-table tbody tr.selected td:first-child,
#app[data-theme-style='light-glass'] .custom-table tbody tr.table-tr.selected td:first-child {
  border-left-color: rgba(33, 133, 160, 0.22);
}

#app[data-theme-style='light-glass'] .custom-table tbody tr.selected td:last-child,
#app[data-theme-style='light-glass'] .custom-table tbody tr.table-tr.selected td:last-child {
  border-right-color: rgba(33, 133, 160, 0.22);
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

- [ ] **Step 3: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): light-glass floating row pill shape"
```

---

## Task 5: Header `th` styles — both themes

Override the header appearance: uppercase Space Grotesk, accent colour, no background, no border-bottom.

**Files:**
- Modify: `src/styles/style.scss` — append after Task 4 block

- [ ] **Step 1: Find existing glass `th` override to understand what's already set**

The existing rule around line 997 sets `background: var(--surface)` on `th`. We need to override that for the table context specifically.

- [ ] **Step 2: Append header overrides**

```scss
/* ── Glass table: header th ── */

#app[data-theme-style='dark-glass'] .custom-table th,
#app[data-theme-style='dark-glass'] .custom-table th.fixed-cell {
  background: transparent;
  border-top: none;
  border-bottom: none;
  backdrop-filter: none;
  -webkit-backdrop-filter: none;
}

#app[data-theme-style='dark-glass'] .custom-table .table-th {
  background-color: transparent;
  color: rgba(89, 214, 207, 0.52);
  font-family: 'Space Grotesk', sans-serif;
  font-size: 9.5px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

#app[data-theme-style='light-glass'] .custom-table th,
#app[data-theme-style='light-glass'] .custom-table th.fixed-cell {
  background: transparent;
  border-top: none;
  border-bottom: none;
  backdrop-filter: none;
  -webkit-backdrop-filter: none;
}

#app[data-theme-style='light-glass'] .custom-table .table-th {
  background-color: transparent;
  color: #2185a0;
  font-family: 'Space Grotesk', sans-serif;
  font-size: 9.5px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
```

- [ ] **Step 3: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): glass header th — uppercase Space Grotesk, accent colour"
```

---

## Task 6: Resize handle and drag-indicator affordances

The `.resize-column-thumb` already exists and shows on `thead:hover`. Override its colours to match the glass accent. The drag grip (`drag_indicator` icon) already has a colour from `.table-th .material-icons` — override that.

**Files:**
- Modify: `src/styles/style.scss` — append after Task 5 block

- [ ] **Step 1: Append resize and drag affordance overrides**

```scss
/* ── Glass table: resize handle & drag affordance ── */

#app[data-theme-style='dark-glass'] .custom-table .resize-column-thumb {
  background-color: rgba(89, 214, 207, 0.12);
  width: 4px;
}

#app[data-theme-style='dark-glass'] .custom-table .resize-column-thumb .material-icons {
  color: rgba(89, 214, 207, 0.55);
  font-size: 0.7rem;
}

#app[data-theme-style='dark-glass'] .custom-table th .table-th .material-icons {
  color: rgba(89, 214, 207, 0.45);
}

#app[data-theme-style='light-glass'] .custom-table .resize-column-thumb {
  background-color: rgba(33, 133, 160, 0.10);
  width: 4px;
}

#app[data-theme-style='light-glass'] .custom-table .resize-column-thumb .material-icons {
  color: rgba(33, 133, 160, 0.50);
  font-size: 0.7rem;
}

#app[data-theme-style='light-glass'] .custom-table th .table-th .material-icons {
  color: rgba(33, 133, 160, 0.45);
}

/* Column drop-target indicator */
#app[data-theme-style='dark-glass'] .custom-table th.column-drop-target {
  outline-color: rgba(89, 214, 207, 0.6);
}

#app[data-theme-style='light-glass'] .custom-table th.column-drop-target {
  outline-color: rgba(33, 133, 160, 0.5);
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

- [ ] **Step 3: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): accent resize handle and drag indicator colours"
```

---

## Task 7: Vertical dividers (opt-in setting)

When `show-vertical-borders` class is present on `.table-wrapper`, `td + td` gets a border-left. Override the default grey with glass-appropriate subtle lines. The existing rule adds `border-right` to `th`/`td` — we override the colour and reset the pill shape for last cell.

**Files:**
- Modify: `src/styles/style.scss` — append after Task 6 block

- [ ] **Step 1: Append vertical divider overrides**

```scss
/* ── Glass table: vertical dividers (opt-in) ── */

#app[data-theme-style='dark-glass'] .custom-table.show-vertical-borders tbody tr td + td {
  border-left: 1px solid rgba(255, 255, 255, 0.07);
}

#app[data-theme-style='dark-glass'] .custom-table.show-vertical-borders tbody tr:hover td + td {
  border-left-color: rgba(89, 214, 207, 0.13);
}

#app[data-theme-style='dark-glass'] .custom-table.show-vertical-borders th {
  border-right: 1px solid rgba(89, 214, 207, 0.10);
}

#app[data-theme-style='dark-glass'] .custom-table.show-vertical-borders th:last-child {
  border-right: none;
}

#app[data-theme-style='light-glass'] .custom-table.show-vertical-borders tbody tr td + td {
  border-left: 1px solid rgba(196, 182, 163, 0.18);
}

#app[data-theme-style='light-glass'] .custom-table.show-vertical-borders tbody tr:hover td + td {
  border-left-color: rgba(33, 133, 160, 0.15);
}

#app[data-theme-style='light-glass'] .custom-table.show-vertical-borders th {
  border-right: 1px solid rgba(33, 133, 160, 0.12);
}

#app[data-theme-style='light-glass'] .custom-table.show-vertical-borders th:last-child {
  border-right: none;
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

- [ ] **Step 3: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): glass vertical dividers — subtle accent lines"
```

---

## Task 8: Footer row, fixed-column border, and `@supports` fallback

The footer row uses `.table-footer-row .table-footer-cell`. Fixed column border line needs to stay visible. Add the `@supports not (backdrop-filter)` fallback for the new transparent cells.

**Files:**
- Modify: `src/styles/style.scss` — append after Task 7 block; also update existing `@supports` block at the very end

- [ ] **Step 1: Append footer and fixed-column border overrides**

```scss
/* ── Glass table: footer row ── */

#app[data-theme-style='dark-glass'] .custom-table .table-footer-row .table-footer-cell {
  background: rgba(255, 255, 255, 0.035);
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  border-bottom: none;
  color: rgba(149, 167, 182, 0.7);
}

#app[data-theme-style='light-glass'] .custom-table .table-footer-row .table-footer-cell {
  background: rgba(255, 255, 255, 0.40);
  border-top: 1px solid rgba(196, 182, 163, 0.22);
  border-bottom: none;
  color: rgba(111, 106, 98, 0.7);
}

/* ── Fixed column shadow border ── */

#app[data-theme-style='dark-glass'] .custom-table.show-fixed-column-border ::v-deep .last-fixed-cell {
  border-right: 1px solid rgba(89, 214, 207, 0.15);
}

#app[data-theme-style='light-glass'] .custom-table.show-fixed-column-border ::v-deep .last-fixed-cell {
  border-right: 1px solid rgba(33, 133, 160, 0.15);
}
```

- [ ] **Step 2: In the existing `@supports not (backdrop-filter: blur(1px))` block at the end of the file, add fallbacks for the new transparent td backgrounds**

Find the block:
```scss
@supports not (backdrop-filter: blur(1px)) {
  #app[data-theme-style='light-glass'] .header-panel,
  ...
  #app[data-theme-style='dark-glass'] .form_inline_block {
    background: var(--card) !important;
  }
}
```

Add inside that block before the closing `}`:
```scss
  #app[data-theme-style='dark-glass'] .custom-table tbody tr td {
    background: rgba(17, 32, 46, 0.85) !important;
  }

  #app[data-theme-style='light-glass'] .custom-table tbody tr td {
    background: rgba(255, 255, 255, 0.88) !important;
  }
```

- [ ] **Step 3: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): footer, fixed-column border, @supports fallback"
```

---

## Task 9: Remove horizontal row divider line (`td` border-bottom) inherited from default styles

The default `.custom-table ::v-deep td` sets `border-bottom` for row separation. With `border-spacing` this produces a double line effect. Override to `none` for glass themes.

**Files:**
- Modify: `src/styles/style.scss` — append after Task 8 block (the glass table section)

- [ ] **Step 1: Check the existing default border-bottom rule**

Find around line 4200 in Table.vue styles (scoped):
```scss
::v-deep td {
  border-bottom: 1px solid var(--table-horizontal-borderColor, var(--table-borderColor));
}
```

This is a scoped style inside `Table.vue` — it becomes `[data-v-xxx] td`. We need to override it in `style.scss` with higher specificity.

- [ ] **Step 2: Append override**

```scss
/* ── Glass table: remove default td border-bottom (replaced by pill borders) ── */

#app[data-theme-style='dark-glass'] .custom-table tbody td {
  border-bottom: none !important;
}

#app[data-theme-style='light-glass'] .custom-table tbody td {
  border-bottom: none !important;
}

/* Also remove the horizontal border inherited on th */
#app[data-theme-style='dark-glass'] .custom-table thead tr {
  border-bottom: none;
}

#app[data-theme-style='light-glass'] .custom-table thead tr {
  border-bottom: none;
}
```

- [ ] **Step 3: Build**

```bash
cd /Users/vientooscuro/SyncFolder/ozma && yarn build 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add src/styles/style.scss
git commit -m "feat(glass-table): remove default td border-bottom, use pill borders only"
```

---

## Self-review checklist

**Spec coverage:**
- [x] Floating rows with `border-collapse: separate` + `border-spacing: 0 6px` → Task 2
- [x] `border-radius: 14px` on first/last `td` → Tasks 3, 4
- [x] Dark-glass row styles (bg, border, hover, selected) → Task 3
- [x] Light-glass row styles (bg, border, hover, selected, box-shadow) → Task 4
- [x] Header `th`: Space Grotesk, uppercase, accent colour, no background → Task 5
- [x] Resize handle colour override → Task 6
- [x] Drag grip (`drag_indicator`) colour override → Task 6
- [x] Column drop-target indicator colour → Task 6
- [x] Vertical dividers opt-in (`show-vertical-borders`) → Task 7
- [x] Footer row glass styling → Task 8
- [x] Fixed-column border colour → Task 8
- [x] `@supports` fallback for no-backdrop-filter browsers → Task 8
- [x] Remove conflicting default `td border-bottom` → Task 9
- [x] New branch → Task 1

**Placeholder scan:** No TBD/TODO present.

**Type consistency:** No types — pure CSS. Class names used consistently: `.custom-table`, `.table-th`, `.resize-column-thumb`, `.column-drop-target`, `show-vertical-borders`, `.table-footer-row`, `.table-footer-cell`, `.last-fixed-cell`.
