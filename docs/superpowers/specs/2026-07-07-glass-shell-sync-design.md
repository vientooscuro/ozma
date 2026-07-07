# Glass Shell Sync (Phase 2) — structural sync with the reference CRM screen

**Date:** 2026-07-07
**Status:** approved direction ("дизайн должен быть максимально синхронизирован, даже если это потребует больших изменений"); tab source and theme gating chosen by user.
**Reference:** the design-system ui-kit screen «Студенты» (user-provided screenshot; source mockup in `~/Downloads/Новый дизайн экранов/_ds/*/ui_kits/crm`). Phase 1 (Glass Themes 2.0, spec `2026-07-07-glass-themes-v2-design.md`) delivered tokens/components; this phase syncs the page STRUCTURE.

## 1. Scope and gating

Four workstreams, in increasing depth: (A) CSS table polish, (B) numbered pagination, (C) page header + toolbar card, (D) brand bar with tabs.

**Everything is gated to the two new themes** (`dark-glass`, `light-glass-cool`): components render the new layout only when the active theme is one of them (same reactive mechanism as `AppIcon` — `settings.currentThemeRef`). The frozen warm `light-glass` and default themes keep the exact current DOM and behavior.

## 2. Workstream A — CSS table polish (glass2.scss only)

1. **Main column emphasis:** the first data column (after the select/edit utility cells) renders semibold 600 in `--text-primary` — like «ФАМИЛИЯ» in the reference. Implementation targets the actual utility-cell classes of `TableRow.vue` (investigated at plan time), not brittle nth-child guesses; if utility cells prove non-deterministic, this item is done via a cell class emitted by `TableCell.vue` for the first data column.
2. **Boolean cells:** render as the reference checks — true: 18px rounded-square (radius 6) filled `--success` with dark check glyph; false/empty: bordered square `--border-default`, transparent. CSS-only restyle of the existing bool-cell checkbox markup.
3. **Empty values:** empty data cells show «—» in `--text-disabled` (CSS `:empty::before`; verified against actual cell markup at plan time, dropped silently for cell types where markup never renders empty).
4. Emails/phones/telegram links keep `--link` color (already done in Phase 1); phones additionally get `glass2-mono`.

## 3. Workstream B — numbered pagination (Table.vue)

Reference footer: `НАЗАД  [1] 2 3 … 397  ВПЕРЕД`.

- In glass2 themes the pagination block renders: caps text-button «НАЗАД», page number buttons with ellipsis windowing (1 … p-1 [p] p+1 … N; ≤7 slots), caps text-button «ВПЕРЕД». Current page = accent pill (`--gradient-accent`, `--text-on-accent`).
- Clicking a page number jumps to it (offset = page × perPage via the existing lazyLoad pagination model; the component already computes `currentVisualPage` and page count).
- Old themes keep the existing first/prev/next arrows markup untouched (`v-if` on the glass2-theme getter).
- The «Строк на странице» select and the «1–50» counter stay, restyled caps (already done in Phase 1).

## 4. Workstream C — page header + toolbar card (root views only)

Applies to the ROOT view header only; nested user views and modal headers keep their current compact glass2 header.

**Row 1 — page header** (transparent, on the shell background):
- Left: back + home compact icon buttons (existing), then an icon tile 40px (radius 12, `--accent-tint` background, accent icon; icon comes from the view's existing icon attribute if present, otherwise a default `table` glyph), then title 24px/700/-0.01em with the record counter in `--text-muted`, and under them a caps micro-label subtitle — the view's description attribute; omitted when absent.
- Right: the view's PRIMARY action (the create/«Новая запись» button, identified from the existing header buttons model at plan time) as the gradient CTA pill with glow.
- The user avatar moves to the brand bar (workstream D); if the brand bar is not rendered (mobile fallback), avatar stays here.

**Row 2 — toolbar card** (glass card `--surface-card`, radius 16, border `--border-subtle`, padding 10–12px):
- Left: the search input rendered as a visible field («Поиск…», ~280px, inset well) instead of an icon-only toggle, then sort + filter as bordered icon buttons.
- Right: the remaining secondary header buttons as glass chips, then the ellipsis menu.

Implementation: conditional layout inside `HeaderPanel.vue`/`TopLevelUserView.vue` (theme-gated `v-if`), reusing the existing buttons/search models — no new data plumbing. Styling in glass2.scss.

## 5. Workstream D — brand bar with tabs (new component)

A fixed top bar (~52px, full width, `--surface-card` + `--glass-blur`, bottom border `--border-subtle`), rendered above the page header in glass2 themes only:

- **Left — brand:** accent-gradient mini-tile + instance name. Name source: `funapp.settings` key `brand_title`; fallback «Ozma».
- **Tabs — main menu categories:** tab per category of the main menu (the same user view the menu screen renders, loaded once into the store and cached). Active tab = pill (`--accent-tint` bg, accent text) — determined by whether the current view belongs to that category's items; no match → no active tab. Click opens a glass dropdown with the category's entries (same links as the menu screen). With 9+ categories the tab row scrolls horizontally (no wrapping); on mobile the bar shows brand + theme toggle + avatar only.
- **Right:** theme quick-toggle (sun/moon switching dark-glass ↔ light-glass-cool via the existing `setCurrentTheme` action) + the profile avatar button (moved from the header panel).
- The main menu screen itself remains reachable (home button in page header row).

## 6. Out of scope

- Warm/default themes: zero DOM/behavior changes (gating).
- New DB entities. Optional additions only: `funapp.settings.brand_title` read-if-present.
- Report generator, mobile-specific redesign beyond the stated fallbacks.

## 7. Verification

1. Side-by-side with the reference screenshot: students-like table view in dark-glass — brand bar, page header with icon tile + counter, toolbar card, bold first column, boolean checks, numbered pagination.
2. Both new themes × (menu, table, form, Monaco) — no layout breakage from the new bars (sticky offsets, z-index, modals).
3. Warm theme regression: DOM identical (the gating `v-if` short-circuits) — verified by computed-style fingerprint on the reference screens.
4. Mobile viewport sanity in new themes.
5. `yarn lint`, `yarn lint:style`, full docker rebuild.

## 8. Risks

- **HeaderPanel restructure** touches the most shared component; mitigated by rendering the new layout only for root + glass2 and keeping the legacy branch byte-identical.
- **Category→view matching** for the active tab is heuristic (URL match against category items); acceptable to have no active tab on unmatched views.
- **Sticky stacking:** brand bar + sticky header + sticky table header need a reviewed z-index/offset ladder in glass2.scss.
