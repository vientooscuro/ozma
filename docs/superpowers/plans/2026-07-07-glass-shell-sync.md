# Glass Shell Sync (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Structurally sync the ozma frontend with the reference CRM screen («Студенты») for the two Glass 2.0 themes only (`dark-glass`, `light-glass-cool`): table cell polish, numbered pagination, root page header + toolbar card, and a brand bar with main-menu tabs — while keeping the warm `light-glass` and default themes DOM- and behavior-identical.

**Architecture:** All component changes are theme-gated with a shared `isGlass2Theme(currentThemeRef)` helper (same reactive mechanism as `AppIcon`): every touched component renders its legacy markup verbatim in a `v-else`/absent-class branch for non-glass2 themes. New styling lives exclusively in `src/styles/glass2.scss` (mixins instantiated under `#app[data-theme-style='dark-glass'], #app[data-theme-style='light-glass-cool']`, so rules never leak into warm themes). The brand bar gets its main-menu categories from a new cached Vuex module that loads the `user.main` view once via the raw API.

**Tech Stack:** Vue 2.7 + TypeScript class components (vue-property-decorator, vuex-class), Vuex 3, bootstrap-vue, SCSS via @vue/cli-service 5, vendored Lucide SVGs (`src/utils/lucideIcons.ts`), `@ozma-io/ozmadb-js` client.

---

## Important context for the implementer

- **Spec (authoritative):** `/Users/vientooscuro/SyncFolder/ozma/docs/superpowers/specs/2026-07-07-glass-shell-sync-design.md`. Section references (§N) point to it. Phase 1 spec for token/component vocabulary: `docs/superpowers/specs/2026-07-07-glass-themes-v2-design.md`.
- **Repo:** `/Users/vientooscuro/SyncFolder/ozma`, branch `glass-themes-2` (Phase 1 is complete and committed on it — keep working on this branch).
- **Verification commands:**
  - `YARN_NODE_LINKER=node-modules yarn lint` — eslint (auto-fixes). Success output ends with `DONE No lint errors found!` — 1 pre-existing warning (`v-html` in AppIcon.vue) is expected and OK.
  - `YARN_NODE_LINKER=node-modules yarn lint:style` — stylelint. Must exit 0; ~686 pre-existing warnings are OK (defaultSeverity is warning), 0 errors required.
  - `./local_rebuild_and_publish.sh --only_ui` — the ONLY sanctioned rebuild path; also the de-facto TypeScript type-check/build gate. Run it in FOREGROUND with timeout up to 600000 ms at the marked **Visual checkpoint** steps, not after every edit.
- **There is NO unit-test infrastructure** (no vitest/jest). Where TDD would normally apply, verification is instead: `yarn lint` + `yarn lint:style` + full docker rebuild (type-check) + the explicit visual checkpoints below (the controller drives a real browser at `http://localhost:9080`).
- **Reference mockup:** `~/Downloads/Новый дизайн экранов` (`_ds/*/ui_kits/crm` — the «Студенты» CRM screen). Serve with `python3 -m http.server 8899 --directory "/Users/vientooscuro/Downloads/Новый дизайн экранов"` if a side-by-side is needed.
- **Theme switching in the app:** avatar (profile button, top right) → theme entries. The two new themes are «dark-glass» and «light-glass-cool»; the frozen warm theme is «light-glass».
- **CRITICAL warm-theme freeze rule:** every component change in this plan MUST render the legacy branch byte-identical for non-glass2 themes. New template markup goes behind `v-if="<glass2 condition>"` with the old markup preserved verbatim in `v-else` (or the new prop/class simply absent). New events/props are DOM-invisible and therefore safe. Each task's verification step includes a warm-theme spot-check; the final task does the full regression.
- **Commit style:** one commit per task, short one-line English imperative title, no body, no backticks, no Co-Authored-By.

## File structure

| File | Status | Responsibility |
|---|---|---|
| `src/styles/glass2.scss` | modify (append + one in-place mixin rewrite) | All Phase 2 styling: table polish (§2), numbered pager (§3), page header + toolbar card (§4), brand bar + shell layout + z-ladder (§5) |
| `src/utils/glass2.ts` | create | Single source of truth for glass2 theme detection: `isGlass2Theme(themeRef)` |
| `src/components/AppIcon.vue` | modify (~line 30-40) | Reuse the shared helper instead of its private literal check |
| `src/utils/lucideIcons.ts` | modify (3 svg entries + 3 map entries) | Vendored `sun`, `moon`, `table` glyphs; `light_mode`/`dark_mode`/`table` material mappings |
| `src/components/views/Table.vue` | modify (i18n block; template ~475-519; script ~1687, ~2246+) | Glass2 numbered pagination branch (legacy arrows kept verbatim in `v-else`); `update:row-count` emit |
| `src/components/UserView.vue` | modify (~line 186, ~543, ~1157) | Pass-through of `update:row-count`; new `viewIcon` getter + `update:icon` emit |
| `src/components/TopLevelUserView.vue` | modify (template ~62-107; script) | Holds `viewIcon`/`rowCount`, passes them to HeaderPanel; mounts BrandBar; hides header avatar in glass2 |
| `src/components/panels/HeaderPanel.vue` | modify (template split; script props/getters) | Glass2 root layout: page header row (icon tile, 24px title, counter, subtitle, CTA) + toolbar card row; legacy branch verbatim |
| `src/components/SearchPanel.vue` | modify (2 template attrs, script prop + `created`) | New opt-in `expanded` prop (always-open visible search field); default behavior byte-identical |
| `src/state/main_menu.ts` | create | Vuex module: loads + caches `user.main` categories as brand-bar tabs (both menu formats) |
| `src/main.ts` | modify (import + modules map) | Register the `mainMenu` module |
| `src/components/BrandBar.vue` | create | Brand bar: brand tile + name, category tabs with dropdowns, theme quick-toggle, ProfileButton |

## Z-index / layout ladder (reviewed, §8)

Top to bottom in glass2 themes: overlays/modals `100050` (Phase 1 `glass2-overlays`) → **brand bar `120`** (new) → sticky root header `100` (Phase 1 `glass2-header`) → table sticky header/fixed cells `0–1` (Phase 1 `glass2-table-fixed`). The brand bar is a static flex row (the page scroll container is `.userview-div`, so nothing scrolls past it); `.main-div > .userview-upper-div` switches from `height: inherit` to `flex: 1 1 0; height: auto; min-height: 0` in glass2 only, so the 52px bar doesn't overflow the viewport.

---

## Task 1: Workstream A — table cell polish (glass2.scss only)

CSS-only. Four items from §2: bold first data column, boolean check squares, «—» for empty cells, mono phones. Verified facts from the code:

- Utility cells in `src/components/views/table/TableRow.vue`: `td.fixed-cell.select-row-cell` (optional, always first when present) then `td.fixed-cell.add-entry-cell` (optional), then data `<TableCell>` tds. Both are optional ⇒ four deterministic sibling-combinator selectors cover every layout (no nth-child guesses).
- Boolean cells in `src/components/views/table/TableCell.vue` line 78-84: `<Checkbox class="checkbox_click-none" :checked="value.value" />` when not null; nothing when null. `src/components/checkbox/Checkbox.vue` renders an 18px SVG `rect.checkbox-rect` (`rx=4` attr) and exposes `--checkbox-background` / `--checkbox-foreground` custom-property hooks for fill/check colors. Radius 6 is set via the CSS `rx` geometry property (SVG2; Chromium/Firefox honor it, older Safari keeps the attr value 4 — graceful).
- Empty cells: text cells always render `<span class="text" v-html="valueHtml || '&nbsp;'" />` (TableCell.vue line 129) — never `:empty`. Only null-boolean cells leave `.td-content` with just a `v-if` comment placeholder (comments do not defeat `:empty`). Per §2.3's own escape hatch the dash is therefore applied only where markup can actually be empty (see Appendix, deviation 1).
- Phones render as `<a href="tel:...">` produced by `src/utils.ts` (`'tel:' + telMatch[0]`, line ~937). Link color already comes from Phase 1.
- All rules instantiate under `#app[data-theme-style='dark-glass'], #app[data-theme-style='light-glass-cool']` — specificity `(1,3,x)` beats every scoped-component rule they override (scoped rules are `(0,2-4,0)`).

**Warm-theme freeze:** no component files touched; all new rules are gated under the glass2 attribute selectors ⇒ warm DOM and computed styles untouched by construction.

**Files:**
- Modify: `src/styles/glass2.scss` (append after the final `light-glass-cool` specifics block, current end of file ~line 1228)

- [ ] **Step 1: Append the table-polish mixin to glass2.scss**

Open `/Users/vientooscuro/SyncFolder/ozma/src/styles/glass2.scss` and append at the very end of the file (after the closing `}` of the `#app[data-theme-style='light-glass-cool']` block that ends the file):

```scss

/* ── Phase 2 §2 — table cell polish ── */
@mixin glass2-table-polish {
  /* §2.1 Main (first data) column: semibold, primary color. The two utility
     cells (.select-row-cell, .add-entry-cell) are each optional, so cover
     all four layouts with sibling combinators instead of nth-child. */
  .custom-table tbody td.select-row-cell + td.add-entry-cell + td,
  .custom-table tbody td.select-row-cell + td:not(.add-entry-cell),
  .custom-table tbody tr > td.add-entry-cell:first-child + td,
  .custom-table
    tbody
    tr
    > td:first-child:not(.select-row-cell):not(.add-entry-cell) {
    color: var(--text-primary);
    font-weight: 600;
  }

  /* §2.2 Boolean cells (TableCell renders <Checkbox class="checkbox_click-none">):
     true = filled --success rounded square with dark check glyph,
     false = bordered transparent square. Selection checkboxes (plain
     .checkbox in .select-row-cell) are deliberately not matched. */
  .custom-table .checkbox_click-none {
    --checkbox-background: var(--success);
    --checkbox-foreground: var(--text-on-accent);

    justify-content: center;
    padding-top: 0;
  }

  .custom-table .checkbox_click-none:hover,
  .custom-table .checkbox_click-none:active {
    background: transparent;
  }

  .custom-table .checkbox_click-none .checkbox-rect {
    rx: 6px;
    stroke: var(--border-default);
  }

  .custom-table .checkbox_click-none .checkbox-rect.checked {
    fill: var(--success);
    stroke: var(--success);
  }

  /* §2.3 Empty values: em dash in --text-disabled. Only cells whose
     .td-content is genuinely empty (null booleans) match :empty; text cells
     always render an &nbsp; placeholder (see plan appendix). */
  .custom-table tbody td .td-content:empty::before {
    content: '—';
    color: var(--text-disabled);
  }

  /* §2.4 Phones in mono (emails/phones/telegram already use --link from
     Phase 1). */
  .custom-table .cell-text a[href^='tel:'] {
    @include glass2-mono;

    font-size: 12.5px;
  }
}

#app[data-theme-style='dark-glass'],
#app[data-theme-style='light-glass-cool'] {
  @include glass2-table-polish;
}
```

- [ ] **Step 2: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint:style
```

Expected: exit code 0, warnings only (no errors). If `rx` triggers a `property-no-unknown` message it will be a warning (defaultSeverity), not a failure — leave it.

```bash
YARN_NODE_LINKER=node-modules yarn lint
```

Expected: `DONE No lint errors found!` (plus the 1 pre-existing AppIcon v-html warning).

- [ ] **Step 3: Visual checkpoint (build + browser)**

```bash
./local_rebuild_and_publish.sh --only_ui
```

Run in foreground (timeout up to 600000 ms). Expected: build completes without TypeScript/SCSS errors and republishes the local frontend.

Then in the browser at `http://localhost:9080`:
1. Switch to «dark-glass» (avatar → theme). Open any root table view with data.
2. Verify: the first data column (after checkbox/edit utility cells) is semibold in the primary text color; other columns unchanged.
3. Find a boolean column: true = filled green rounded square with dark check; false = subtle bordered transparent square; null = «—» in disabled color. Row-selection checkboxes on the left are NOT green.
4. Find a phone value: renders in JetBrains Mono, link-colored.
5. Repeat spot-checks in «light-glass-cool».
6. Switch to «light-glass» (warm): table looks exactly as before this task (no bold first column, old checkboxes, no dashes).

- [ ] **Step 4: Commit**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
git add src/styles/glass2.scss
git commit -m "style(glass2): bold first column, boolean checks and cell polish"
```

---

## Task 2: Shared glass2-theme helper + new Lucide icons + AppIcon refactor

Prep for every component task that follows. Creates the single `isGlass2Theme` helper (so the `'dark-glass' | 'light-glass-cool'` literals live in exactly one place), refactors `AppIcon.vue` onto it, and vendors the three new Lucide glyphs needed later (`table` for the header icon tile default, `sun`/`moon` for the brand-bar theme toggle).

**No unit-test infra** — verification is lint + (deferred) build; AppIcon behavior is re-checked visually at the Task 3 checkpoint (icons are everywhere).

**Warm-theme freeze:** pure refactor of AppIcon's internal getter (same semantics); icon additions only extend lookup maps. No DOM change in any theme.

**Files:**
- Create: `src/utils/glass2.ts`
- Modify: `src/components/AppIcon.vue` (script only, lines ~13-41)
- Modify: `src/utils/lucideIcons.ts` (svg dict + material map, alphabetical positions)

- [ ] **Step 1: Create the helper**

Create `/Users/vientooscuro/SyncFolder/ozma/src/utils/glass2.ts`:

```ts
import type { IThemeRef } from '@/utils_colors'

// Single source of truth for "is the active theme one of the Glass 2.0
// themes". Everything structurally gated in Phase 2 (brand bar, page
// header, numbered pagination) must use this helper, never inline
// theme-name literals.
export const isGlass2Theme = (themeRef: IThemeRef | null): boolean => {
  const name = themeRef?.name
  return name === 'dark-glass' || name === 'light-glass-cool'
}
```

- [ ] **Step 2: Refactor AppIcon.vue onto the helper**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/AppIcon.vue`, replace:

```ts
import type { IThemeRef } from '@/utils_colors'
import { lucideMarkupForMaterialName } from '@/utils/lucideIcons'
```

with:

```ts
import type { IThemeRef } from '@/utils_colors'
import { isGlass2Theme } from '@/utils/glass2'
import { lucideMarkupForMaterialName } from '@/utils/lucideIcons'
```

and replace:

```ts
  private get isGlass2Theme(): boolean {
    const themeName = this.currentThemeRef?.name
    return themeName === 'dark-glass' || themeName === 'light-glass-cool'
  }
```

with:

```ts
  private get isGlass2Theme(): boolean {
    return isGlass2Theme(this.currentThemeRef)
  }
```

- [ ] **Step 3: Vendor the three new Lucide glyphs**

All three were copied verbatim from `https://unpkg.com/lucide-static@1.23.0/icons/{table,sun,moon}.svg` (inner elements only, outer `<svg>` stripped) — do not alter the path data.

In `/Users/vientooscuro/SyncFolder/ozma/src/utils/lucideIcons.ts`, inside `lucideInnerSvg` (keys are alphabetical):

3a. After the `'maximize'` entry, i.e. replace:

```ts
  'maximize':
    '<path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/>',
  'pencil':
```

with:

```ts
  'maximize':
    '<path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/>',
  'moon':
    '<path d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"/>',
  'pencil':
```

3b. Replace:

```ts
  'square-arrow-out-up-right':
    '<path d="M21 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h6"/><path d="m21 3-9 9"/><path d="M15 3h6v6"/>',
  'trash-2':
```

with:

```ts
  'square-arrow-out-up-right':
    '<path d="M21 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h6"/><path d="m21 3-9 9"/><path d="M15 3h6v6"/>',
  'sun':
    '<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/>',
  'table':
    '<path d="M12 3v18"/><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18"/><path d="M3 15h18"/>',
  'trash-2':
```

- [ ] **Step 4: Extend the material → lucide map**

Same file, inside `materialToLucide` (also alphabetical):

4a. Replace:

```ts
  close: 'x',
  delete: 'trash-2',
```

with:

```ts
  close: 'x',
  dark_mode: 'moon',
  delete: 'trash-2',
```

4b. Replace:

```ts
  home: 'house',
  more_vert: 'ellipsis-vertical',
```

with:

```ts
  home: 'house',
  light_mode: 'sun',
  more_vert: 'ellipsis-vertical',
```

4c. Replace:

```ts
  search_off: 'search-x',
  today: 'calendar-check',
```

with:

```ts
  search_off: 'search-x',
  table: 'table',
  today: 'calendar-check',
```

- [ ] **Step 5: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
```

Expected: `DONE No lint errors found!` (+ the pre-existing AppIcon v-html warning). No build needed yet — Task 3's checkpoint covers it.

- [ ] **Step 6: Commit**

```bash
git add src/utils/glass2.ts src/components/AppIcon.vue src/utils/lucideIcons.ts
git commit -m "refactor: shared glass2 theme helper and new lucide glyphs"
```

---

## Task 3: Workstream B — numbered pagination in Table.vue

Reference footer: `НАЗАД  [1] 2 3 … 397  ВПЕРЕД`. Verified pagination model in `src/components/views/Table.vue`:

- The block renders when `uv.extra.lazyLoad.type === 'pagination'` (template lines ~475-519).
- `pagination.currentPage` is 0-based; `pagesCount` (getter, ~line 2248) is `null` until `uv.rowLoadState.complete` (total unknown while rows are still fetched lazily), then `ceil(fetchedRowCount / perPage)`.
- `goToPage(page)` (private method, ~line 2083) already handles jumps including lazy chunk loading via `load-entries` — reuse it as-is for number clicks.
- `goToPrevPage()` / `goToNextPage()` handle the back/forward text buttons; next-disabled logic mirrors the legacy `nextPageButton` getter (~line 2010).
- `settingsStore = namespace('settings')` already exists (~line 1653); Vue class templates can call private members.

**Warm-theme freeze:** the whole legacy `.pagination` inner markup is preserved verbatim in a `v-else` branch; the glass2 branch renders only when `isGlass2Theme` is true. New script members are additive.

**No unit-test infra** — verification = lint + build + visual checkpoint below.

**Files:**
- Modify: `src/components/views/Table.vue` (i18n block lines ~4/34/64; template lines ~475-519; script imports ~line 626, class members ~line 1690, getters after `pagesCount` ~line 2259)
- Modify: `src/styles/glass2.scss` (rewrite the `glass2-pagination` mixin block in place, lines ~1172-1210)

- [ ] **Step 1: Add i18n keys for the caps text buttons**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/views/Table.vue`, the `<i18n>` block. Three edits (caps come from CSS `text-transform`, so plain words here):

Replace:

```json
      "pagination_select": "Rows per page",
```

with:

```json
      "pagination_select": "Rows per page",
      "pagination_back": "Back",
      "pagination_forward": "Forward",
```

Replace:

```json
      "pagination_select": "Строк на странице",
```

with:

```json
      "pagination_select": "Строк на странице",
      "pagination_back": "Назад",
      "pagination_forward": "Вперед",
```

Replace:

```json
      "pagination_select": "Filas por página",
```

with:

```json
      "pagination_select": "Filas por página",
      "pagination_back": "Atrás",
      "pagination_forward": "Adelante",
```

- [ ] **Step 2: Add imports and the theme binding to the script**

Same file. After the existing `utils_colors` import block:

```ts
import {
  interfaceButtonVariant,
  defaultVariantAttribute,
  outlinedInterfaceButtonVariant,
} from '@/utils_colors'
```

add two lines so it reads:

```ts
import {
  interfaceButtonVariant,
  defaultVariantAttribute,
  outlinedInterfaceButtonVariant,
} from '@/utils_colors'
import type { IThemeRef } from '@/utils_colors'
import { isGlass2Theme } from '@/utils/glass2'
```

Then in the class body, replace:

```ts
  @settingsStore.Action('writeUserSettings') writeUserSettings!: (setting: {
    name: string
    value: string
  }) => Promise<void>
```

with:

```ts
  @settingsStore.Action('writeUserSettings') writeUserSettings!: (setting: {
    name: string
    value: string
  }) => Promise<void>
  @settingsStore.State('currentThemeRef') currentThemeRef!: IThemeRef | null

  get isGlass2Theme(): boolean {
    return isGlass2Theme(this.currentThemeRef)
  }
```

- [ ] **Step 3: Add the page-slot model to the script**

Same file, module scope (top-level, right before the `@UserView({` decorator at ~line 1655), add:

```ts
type Glass2PaginationSlot =
  | { type: 'page'; page: number }
  | { type: 'ellipsis'; key: string }
```

In the class body, directly after the closing brace of the `pagesCount` getter:

```ts
  private get pagesCount(): number | null {
    if (
      this.uv.extra.lazyLoad.type !== 'pagination' ||
      !this.uv.rowLoadState.complete
    )
      return null

    return Math.ceil(
      this.uv.rowLoadState.fetchedRowCount /
        this.uv.extra.lazyLoad.pagination.perPage,
    )
  }
```

add:

```ts
  get glass2CurrentPage(): number {
    if (this.uv.extra.lazyLoad.type !== 'pagination') return 0
    return this.uv.extra.lazyLoad.pagination.currentPage
  }

  get glass2PrevPageDisabled(): boolean {
    return this.glass2CurrentPage === 0
  }

  get glass2NextPageDisabled(): boolean {
    if (this.uv.extra.lazyLoad.type !== 'pagination') return true
    return (
      (this.uv.rowLoadState.complete && this.onLastPage) ||
      this.uv.extra.lazyLoad.pagination.loading
    )
  }

  // Ellipsis windowing: 1 … p-1 [p] p+1 … N (≤7 slots). While the total is
  // unknown (rowLoadState not complete ⇒ pagesCount === null) the tail is an
  // open ellipsis without a last-page number.
  get glass2PaginationSlots(): Glass2PaginationSlot[] {
    if (this.uv.extra.lazyLoad.type !== 'pagination') return []
    const current = this.glass2CurrentPage
    const last = this.pagesCount !== null ? this.pagesCount - 1 : null

    const pages = new Set<number>()
    pages.add(0)
    for (let p = current - 1; p <= current + 1; p++) {
      if (p >= 0 && (last === null || p <= last)) pages.add(p)
    }
    if (last !== null) {
      pages.add(Math.max(last, 0))
    } else if (!this.glass2NextPageDisabled) {
      pages.add(current + 1)
    }

    const sorted = Array.from(pages).sort((a, b) => a - b)
    const slots: Glass2PaginationSlot[] = []
    let prev: number | null = null
    for (const page of sorted) {
      if (prev !== null && page - prev > 1) {
        slots.push({ type: 'ellipsis', key: `e${prev}` })
      }
      slots.push({ type: 'page', page })
      prev = page
    }
    if (last === null) {
      slots.push({ type: 'ellipsis', key: 'etail' })
    }
    return slots
  }
```

- [ ] **Step 4: Split the pagination template into glass2 / legacy branches**

Same file, template. Replace the whole block:

```html
          <div
            v-if="uv.extra.lazyLoad.type === 'pagination'"
            class="pagination-wrapper"
          >
            <div class="pagination">
              <b-spinner
                v-if="uv.extra.lazyLoad.pagination.loading"
                class="mr-1"
                small
                label="Next page is loading"
              />
              <div class="current-rows">
                {{ currentRows }}
              </div>
              <div class="select-wrapper">
                <div class="select-label">
                  {{ $t('pagination_select').toString() }}:
                </div>
                <b-select
                  class="page-select"
                  :value="uv.extra.lazyLoad.pagination.perPage"
                  :options="pageSizes"
                  size="sm"
                  @input="updatePageSize"
                />
              </div>
              <ButtonItem
                class="pagination-arrow-button"
                :button="firstPageButton"
              />
              <ButtonItem
                class="pagination-arrow-button"
                :button="prevPageButton"
              />
              <div class="current-page-wrapper">
                <div class="current-page">
                  {{ currentVisualPage }}
                </div>
              </div>
              <ButtonItem
                class="pagination-arrow-button"
                :button="nextPageButton"
              />
            </div>
          </div>
```

with (legacy inner markup preserved verbatim in the `v-else` branch):

```html
          <div
            v-if="uv.extra.lazyLoad.type === 'pagination'"
            class="pagination-wrapper"
          >
            <div v-if="isGlass2Theme" class="pagination glass2-pagination">
              <b-spinner
                v-if="uv.extra.lazyLoad.pagination.loading"
                class="mr-1"
                small
                label="Next page is loading"
              />
              <div class="current-rows">
                {{ currentRows }}
              </div>
              <div class="select-wrapper">
                <div class="select-label">
                  {{ $t('pagination_select').toString() }}:
                </div>
                <b-select
                  class="page-select"
                  :value="uv.extra.lazyLoad.pagination.perPage"
                  :options="pageSizes"
                  size="sm"
                  @input="updatePageSize"
                />
              </div>
              <button
                type="button"
                class="glass2-page-nav"
                :disabled="glass2PrevPageDisabled"
                @click="goToPrevPage"
              >
                {{ $t('pagination_back').toString() }}
              </button>
              <template v-for="pageSlot in glass2PaginationSlots">
                <span
                  v-if="pageSlot.type === 'ellipsis'"
                  :key="pageSlot.key"
                  class="glass2-page-ellipsis"
                >…</span>
                <button
                  v-else
                  :key="'page' + pageSlot.page"
                  type="button"
                  :class="[
                    'glass2-page-number',
                    { current: pageSlot.page === glass2CurrentPage },
                  ]"
                  @click="goToPage(pageSlot.page)"
                >
                  {{ pageSlot.page + 1 }}
                </button>
              </template>
              <button
                type="button"
                class="glass2-page-nav"
                :disabled="glass2NextPageDisabled"
                @click="goToNextPage"
              >
                {{ $t('pagination_forward').toString() }}
              </button>
            </div>
            <div v-else class="pagination">
              <b-spinner
                v-if="uv.extra.lazyLoad.pagination.loading"
                class="mr-1"
                small
                label="Next page is loading"
              />
              <div class="current-rows">
                {{ currentRows }}
              </div>
              <div class="select-wrapper">
                <div class="select-label">
                  {{ $t('pagination_select').toString() }}:
                </div>
                <b-select
                  class="page-select"
                  :value="uv.extra.lazyLoad.pagination.perPage"
                  :options="pageSizes"
                  size="sm"
                  @input="updatePageSize"
                />
              </div>
              <ButtonItem
                class="pagination-arrow-button"
                :button="firstPageButton"
              />
              <ButtonItem
                class="pagination-arrow-button"
                :button="prevPageButton"
              />
              <div class="current-page-wrapper">
                <div class="current-page">
                  {{ currentVisualPage }}
                </div>
              </div>
              <ButtonItem
                class="pagination-arrow-button"
                :button="nextPageButton"
              />
            </div>
          </div>
```

- [ ] **Step 5: Rewrite the glass2-pagination mixin in glass2.scss**

In `/Users/vientooscuro/SyncFolder/ozma/src/styles/glass2.scss`, replace the whole existing block (lines ~1172-1210):

```scss
/* ── Table pagination (§6.4) ── */
@mixin glass2-pagination {
  .pagination .current-rows,
  .pagination .select-label {
    @include glass2-microlabel;
  }

  .pagination .pagination-arrow-button {
    border: 1px solid var(--border-default) !important;
    border-radius: 8px !important;
    background: transparent;
    color: var(--text-primary);
  }

  .pagination .page-select {
    border-color: var(--border-default) !important;
    border-radius: 8px;
    background-color: var(--surface-inset) !important;
    color: var(--text-primary);
  }

  .pagination .current-page-wrapper .current-page {
    display: inline-flex;
    justify-content: center;
    align-items: center;
    min-width: 28px;
    height: 28px;
    padding: 0 8px;
    border-radius: 8px;
    background: var(--gradient-accent);
    color: var(--text-on-accent);
    font-weight: 600;
  }
}
```

with:

```scss
/* ── Table pagination (§6.4 + Phase 2 §3 numbered pager) ──
   In glass2 themes Table.vue renders the numbered pager branch
   (.glass2-pagination); the old arrow/pill rules are gone because that
   legacy markup only renders for non-glass2 themes now. */
@mixin glass2-pagination {
  .pagination .current-rows,
  .pagination .select-label {
    @include glass2-microlabel;
  }

  .pagination .page-select {
    border-color: var(--border-default) !important;
    border-radius: 8px;
    background-color: var(--surface-inset) !important;
    color: var(--text-primary);
  }

  .pagination .glass2-page-nav {
    @include glass2-microlabel;

    cursor: pointer;
    border: none;
    border-radius: 8px;
    background: transparent;
    padding: 6px 10px;
    color: var(--text-secondary);
  }

  .pagination .glass2-page-nav:hover:not(:disabled) {
    background: var(--surface-hover);
    color: var(--text-primary);
  }

  .pagination .glass2-page-nav:disabled {
    cursor: default;
    color: var(--text-disabled);
  }

  .pagination .glass2-page-number {
    @include glass2-mono;

    display: inline-flex;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    border: none;
    border-radius: 8px;
    background: transparent;
    padding: 0 8px;
    min-width: 28px;
    height: 28px;
    color: var(--text-secondary);
    font-size: 12.5px;
    font-weight: 600;
  }

  .pagination .glass2-page-number:hover:not(.current) {
    background: var(--surface-hover);
    color: var(--text-primary);
  }

  .pagination .glass2-page-number.current {
    cursor: default;
    background: var(--gradient-accent);
    color: var(--text-on-accent);
  }

  .pagination .glass2-page-ellipsis {
    padding: 0 2px;
    color: var(--text-disabled);
  }
}
```

(The `#app[data-theme-style=…] { @include glass2-pagination; }` instantiation right after the mixin stays untouched.)

- [ ] **Step 6: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
YARN_NODE_LINKER=node-modules yarn lint:style
```

Expected: `DONE No lint errors found!`; stylelint exit 0 (warnings only).

- [ ] **Step 7: Visual checkpoint**

```bash
./local_rebuild_and_publish.sh --only_ui
```

Then at `http://localhost:9080` in «dark-glass»:
1. Open a root table view with pagination (footer shows «Строк на странице»). Verify: caps «НАЗАД» / «ВПЕРЕД» text buttons, page numbers between them, current page = gradient accent pill with dark numeral.
2. Click a page number ≥ 2 — table jumps to it, pill moves. Click «НАЗАД» — returns. On page 1 «НАЗАД» is disabled (dimmed).
3. On a table larger than one fetch chunk, verify the tail ellipsis appears while the total is unknown, and the last page number appears once all rows are counted (page through to the end or use a small «Строк на странице» value).
4. Repeat a quick look in «light-glass-cool».
5. Switch to «light-glass» (warm): the OLD pagination (first/prev/next arrow buttons + `1/N` pill) renders exactly as before.

- [ ] **Step 8: Commit**

```bash
git add src/components/views/Table.vue src/styles/glass2.scss
git commit -m "feat(glass2): numbered table pagination"
```

---

## Task 4: Workstream C plumbing — view icon and row count events

The glass2 page header needs two data points that exist in the view layer but were never plumbed to the root header: the view's `icon` attribute and the loaded row count. Both travel over NEW Vue events (DOM-invisible ⇒ warm-safe) along the existing chain `Table.vue → UserView.vue → TopLevelUserView.vue` (the same path `update:current-page` already takes — UserView.vue line ~186 re-emits component events).

The spec (§4) says "no new data plumbing" for buttons/search; the counter and icon are impossible without these two events — see Appendix, deviation 2.

**Warm-theme freeze:** events and props only; no template branch changes; DOM identical in all themes.

**Files:**
- Modify: `src/components/UserView.vue` (template ~line 186; script after `description` getter ~line 543; watcher after `updateDescription` ~line 1157)
- Modify: `src/components/views/Table.vue` (script, after the `updateCurrentPageToParent` watcher ~line 2246)
- Modify: `src/components/TopLevelUserView.vue` (template UserView listeners; script data + watcher)

- [ ] **Step 1: UserView.vue — pass through row-count, emit view icon**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/UserView.vue`, template, replace:

```html
            @update:current-page="$emit('update:current-page', $event)"
```

with:

```html
            @update:current-page="$emit('update:current-page', $event)"
            @update:row-count="$emit('update:row-count', $event)"
```

Then in the script, after the `description` getter:

```ts
  get description(): UserString | null {
    if (this.state.state === 'show') {
      const descriptionAttr = rawToUserString(
        this.state.uv.attributes['description'],
      )
      if (descriptionAttr) {
        return descriptionAttr
      }
    }
    return null
  }
```

add:

```ts
  // Icon for the glass2 page header tile (§4): the view's `icon` attribute
  // when present (a Material ligature name), otherwise null (the header
  // falls back to the default `table` glyph).
  get viewIcon(): string | null {
    if (this.state.state === 'show') {
      const iconAttr = this.state.uv.attributes['icon']
      if (typeof iconAttr === 'string') {
        return iconAttr
      }
    }
    return null
  }
```

And after the `updateDescription` watcher:

```ts
  @Watch('description', { immediate: true })
  private updateDescription() {
    this.$emit('update:description', this.description)
  }
```

add:

```ts
  @Watch('viewIcon', { immediate: true })
  private updateViewIcon() {
    this.$emit('update:icon', this.viewIcon)
  }
```

- [ ] **Step 2: Table.vue — emit the complete row count**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/views/Table.vue`, after the `updateCurrentPageToParent` watcher:

```ts
  @Watch('currentVisualPage')
  private updateCurrentPageToParent() {
    if (this.uv.extra.lazyLoad.type !== 'pagination') return
    if (!this.isTopLevel) return

    this.$emit(
      'update:current-page',
      this.uv.extra.lazyLoad.pagination.currentPage,
    )
  }
```

add:

```ts
  // Total row count for the glass2 page header counter (§4). Known only
  // once every row has been fetched; null while loading is incomplete.
  private get completeRowCount(): number | null {
    if (!this.uv.rows || !this.uv.rowLoadState.complete) return null
    return this.uv.rowLoadState.fetchedRowCount
  }

  @Watch('completeRowCount', { immediate: true })
  private updateRowCountToParent() {
    if (!this.isTopLevel) return
    this.$emit('update:row-count', this.completeRowCount)
  }
```

- [ ] **Step 3: TopLevelUserView.vue — hold the values**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/TopLevelUserView.vue`, template, replace:

```html
          @update:current-page="replacePage({ key: null, page: $event })"
```

with:

```html
          @update:current-page="replacePage({ key: null, page: $event })"
          @update:icon="viewIcon = $event"
          @update:row-count="rowCount = $event"
```

In the script, replace:

```ts
  private title: UserString | null = null
  private description: UserString | null = null
```

with:

```ts
  private title: UserString | null = null
  private description: UserString | null = null
  private viewIcon: string | null = null
  private rowCount: number | null = null
```

And after the `errorsChanged` watcher:

```ts
  @Watch('errors')
  private errorsChanged() {
    if (this.errors.length > 0) {
      this.makeErrorToast()
    }
  }
```

add (resets stale values when navigating, e.g. table → form, where Table never mounts and would otherwise leave the old count):

```ts
  @Watch('uvLoading')
  private onUvLoadingChanged(loading: boolean) {
    if (loading) {
      this.viewIcon = null
      this.rowCount = null
    }
  }
```

- [ ] **Step 4: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
```

Expected: `DONE No lint errors found!`. (The values are consumed in Task 5 — `viewIcon`/`rowCount` are referenced from the template already via the new listeners, so no unused-member errors.)

- [ ] **Step 5: Commit**

```bash
git add src/components/UserView.vue src/components/views/Table.vue src/components/TopLevelUserView.vue
git commit -m "feat: plumb view icon and row count to root header"
```

---

## Task 5: Workstream C — HeaderPanel glass2 root layout + SearchPanel expanded prop

Restructures `src/components/panels/HeaderPanel.vue` per §4: for glass2 + `type === 'root'` only, render two rows — the transparent page header (nav slot, 40px icon tile, 24px title + counter + caps subtitle, gradient CTA) and the toolbar card (visible search field, sort + filter icon buttons, secondary chips, ellipsis menu). Everything else (modal/nested headers, all warm themes) renders the legacy markup verbatim.

Verified button model: the create button comes from `UserViewCommon.staticButtons` as `{ icon: 'add', caption: $t('create'), type: 'link' | 'button-group', variant: success }` with `display: undefined`; DB attr buttons may add their own. The primary action is therefore identified as the FIRST button with `icon === 'add'` of an actionable type; it's excluded from the panel/extra sets in the glass2 branch. `buttonsToPanelButtons` and `isHelpButton` already live in the file.

`SearchPanel.vue` today is an icon-only toggle; a new opt-in `expanded` prop makes it an always-open field (used only by the glass2 branch; default `false` keeps warm markup byte-identical because the added `v-if="!expanded"` evaluates true and the `created()` expressions reduce to the old ones).

**Warm-theme freeze:** the entire old `<div class="first-row">…</div>` + `<div class="second-row">…</div>` markup is preserved verbatim inside `<template v-else>`; the root `:class` object gains a key that is absent for warm themes; new props are unused there.

**Files:**
- Modify: `src/components/panels/HeaderPanel.vue` (template fully restructured; script: imports, namespace, 3 props, state binding, 8 getters)
- Modify: `src/components/SearchPanel.vue` (prop + `created` + 2 template `v-if`s)
- Modify: `src/components/TopLevelUserView.vue` (pass 3 new props to HeaderPanel)

- [ ] **Step 1: SearchPanel.vue — add the expanded prop**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/SearchPanel.vue`, script, replace:

```ts
@Component
export default class SearchPanel extends Vue {
  @Prop({ type: String, required: true }) filterString!: string

  private showInput = false
  private showOpenButton = true
  private localFilterString = ''

  created() {
    this.showInput = this.filterString !== ''
    this.showOpenButton = this.filterString === ''
    this.localFilterString = this.filterString
  }
```

with:

```ts
@Component
export default class SearchPanel extends Vue {
  @Prop({ type: String, required: true }) filterString!: string
  // Always-open visible field (glass2 toolbar card). Default keeps the
  // legacy icon-toggle behavior byte-identical.
  @Prop({ type: Boolean, default: false }) expanded!: boolean

  private showInput = false
  private showOpenButton = true
  private localFilterString = ''

  created() {
    this.showInput = this.expanded || this.filterString !== ''
    this.showOpenButton = !this.expanded && this.filterString === ''
    this.localFilterString = this.filterString
  }
```

In the template, replace the close-search append button:

```html
            <b-button
              class="button with-material-icon"
              variant="secondary"
              @click.prevent="toggleShowInput"
            >
              <AppIcon name="search_off" />
            </b-button>
```

with:

```html
            <b-button
              v-if="!expanded"
              class="button with-material-icon"
              variant="secondary"
              @click.prevent="toggleShowInput"
            >
              <AppIcon name="search_off" />
            </b-button>
```

(The `open-search-button` needs no change: with `expanded`, `showOpenButton` starts `false` and `toggleShowInput` is unreachable.)

- [ ] **Step 2: HeaderPanel.vue — script changes**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/panels/HeaderPanel.vue`, replace the import block:

```ts
import { Component, Vue, Prop } from 'vue-property-decorator'
import Popper from '@/components/common/OzmaPopper.vue'

import { debounceTillAnimationFrame } from '@/utils'
import type { IUserViewType } from '@/components/FormControl.vue'
import ButtonItem from '@/components/buttons/ButtonItem.vue'
import type { Button } from '@/components/buttons/buttons'
import { buttonsToPanelButtons } from '@/components/buttons/buttons'
import SearchPanel from '@/components/SearchPanel.vue'
import { interfaceButtonVariant } from '@/utils_colors'
import { UserString, isOptionalUserString } from '@/state/translations'
import ArgumentEditor, {
  IArgumentEditorProps,
} from '@/components/ArgumentEditor.vue'
import SortEditor, { ISortEditorProps } from '@/components/SortEditor.vue'

const isHelpButton = (button: Button) => button.icon === 'help_outline'
```

with:

```ts
import { Component, Vue, Prop } from 'vue-property-decorator'
import { namespace } from 'vuex-class'
import Popper from '@/components/common/OzmaPopper.vue'

import { debounceTillAnimationFrame } from '@/utils'
import type { IUserViewType } from '@/components/FormControl.vue'
import ButtonItem from '@/components/buttons/ButtonItem.vue'
import type { Button } from '@/components/buttons/buttons'
import { buttonsToPanelButtons } from '@/components/buttons/buttons'
import SearchPanel from '@/components/SearchPanel.vue'
import { interfaceButtonVariant } from '@/utils_colors'
import type { IThemeRef } from '@/utils_colors'
import { isGlass2Theme } from '@/utils/glass2'
import { UserString, isOptionalUserString } from '@/state/translations'
import ArgumentEditor, {
  IArgumentEditorProps,
} from '@/components/ArgumentEditor.vue'
import SortEditor, { ISortEditorProps } from '@/components/SortEditor.vue'

const settings = namespace('settings')

const isHelpButton = (button: Button) => button.icon === 'help_outline'
```

Then replace the props block:

```ts
  @Prop({ validator: isOptionalUserString }) title!: UserString | undefined
  @Prop({ type: Array, required: true }) buttons!: Button[]
  @Prop({ type: Boolean, required: true }) isEnableFilter!: boolean
  @Prop({ type: Object }) view!: IUserViewType | undefined
  @Prop({ type: String, required: true }) filterString!: string
  @Prop({ type: Boolean, default: false }) isLoading!: boolean
  @Prop({ type: Object }) argumentEditorProps!: IArgumentEditorProps | null
  @Prop({ type: Object }) sortEditorProps!: ISortEditorProps | null
  @Prop({ type: String }) type!: 'root' | 'modal' | 'nested' | undefined
```

with:

```ts
  @Prop({ validator: isOptionalUserString }) title!: UserString | undefined
  @Prop({ type: Array, required: true }) buttons!: Button[]
  @Prop({ type: Boolean, required: true }) isEnableFilter!: boolean
  @Prop({ type: Object }) view!: IUserViewType | undefined
  @Prop({ type: String, required: true }) filterString!: string
  @Prop({ type: Boolean, default: false }) isLoading!: boolean
  @Prop({ type: Object }) argumentEditorProps!: IArgumentEditorProps | null
  @Prop({ type: Object }) sortEditorProps!: ISortEditorProps | null
  @Prop({ type: String }) type!: 'root' | 'modal' | 'nested' | undefined
  // Glass2 page header extras (§4); ignored by the legacy branch.
  @Prop({ type: String, default: null }) icon!: string | null
  @Prop({ validator: isOptionalUserString }) description!:
    | UserString
    | undefined
  @Prop({ type: Number, default: null }) recordCount!: number | null

  @settings.State('currentThemeRef') currentThemeRef!: IThemeRef | null

  get useGlass2RootLayout(): boolean {
    return isGlass2Theme(this.currentThemeRef) && this.type === 'root'
  }

  // §4: the view's primary action — the create button UserViewCommon builds
  // with icon 'add' (or an equivalent DB-provided one). Rendered as the CTA
  // pill and removed from the toolbar sets below.
  get glass2PrimaryButton(): Button | null {
    if (!this.useGlass2RootLayout) return null
    return (
      this.buttons.find(
        (button) =>
          button.icon === 'add' &&
          (button.type === 'link' ||
            button.type === 'callback' ||
            button.type === 'button-group'),
      ) ?? null
    )
  }

  get glass2PrimaryButtons(): Button[] {
    return this.glass2PrimaryButton ? [this.glass2PrimaryButton] : []
  }

  private get glass2PanelButtons() {
    const primary = this.glass2PrimaryButton
    const rest =
      primary === null
        ? this.buttons
        : this.buttons.filter((button) => button !== primary)
    return buttonsToPanelButtons(rest)
  }

  get glass2HelpButtons(): Button[] {
    return this.glass2PanelButtons.panelButtons.filter(isHelpButton)
  }

  get glass2SecondaryButtons(): Button[] {
    return this.glass2PanelButtons.panelButtons.filter(
      (button) => !isHelpButton(button),
    )
  }

  get glass2ExtraButtons(): Button[] {
    return [this.glass2PanelButtons.extraButton]
  }

  get glass2ToolbarVisible(): boolean {
    return Boolean(
      this.isEnableFilter ||
        this.sortEditorProps ||
        this.argumentEditorProps ||
        this.glass2HelpButtons.length > 0 ||
        this.glass2SecondaryButtons.length > 0 ||
        this.fullscreenButtons.length > 0 ||
        !this.glass2PanelButtons.extraButton.disabled,
    )
  }
```

(The existing getters `extraButtons`, `fullscreenButtons`, `helpButtons`, `headerButtons`, `fullscreenButton` and the compact-layout machinery stay untouched below.)

- [ ] **Step 3: HeaderPanel.vue — template restructure**

Replace the ENTIRE `<template>…</template>` block (lines 1-116) with the following. The `v-else` branch is the current markup verbatim (only re-indented by one level — indentation does not affect DOM):

```html
<template>
  <div
    ref="headerPanel"
    :class="[
      'header-panel',
      {
        'is-root': type === 'root',
        compact: useCompactLayout,
        'glass2-root': useGlass2RootLayout,
      },
    ]"
  >
    <template v-if="useGlass2RootLayout">
      <div class="glass2-page-header">
        <div class="glass2-page-header-left">
          <div v-if="$slots['left-slot']" class="left-slot">
            <slot name="left-slot" />
          </div>
          <div class="glass2-icon-tile">
            <AppIcon :name="icon || 'table'" />
          </div>
          <div class="glass2-title-block">
            <div class="glass2-title-row">
              <div v-if="isLoading" class="title-placeholder" />
              <h1 v-else class="userview-title glass2-page-title">
                {{ $ustOrEmpty(title) }}
              </h1>
              <span v-if="recordCount !== null" class="glass2-record-count">
                {{ recordCount }}
              </span>
            </div>
            <div v-if="description" class="glass2-page-subtitle">
              {{ $ustOrEmpty(description) }}
            </div>
          </div>
        </div>
        <div class="glass2-page-header-right">
          <ButtonsPanel
            v-if="glass2PrimaryButtons.length > 0"
            class="glass2-cta-panel"
            :buttons="glass2PrimaryButtons"
            @goto="$emit('goto', $event)"
          />
          <div v-if="$slots['right-slot']" class="right-slot">
            <slot name="right-slot" />
          </div>
        </div>
      </div>
      <div v-if="glass2ToolbarVisible" class="glass2-toolbar-card">
        <div class="glass2-toolbar-left">
          <SearchPanel
            v-if="isEnableFilter"
            class="search-panel"
            expanded
            :filter-string="filterString"
            @update:filter-string="$emit('update:filter-string', $event)"
          />
          <SortEditor
            v-if="sortEditorProps"
            :sort-editor-props="sortEditorProps"
          />
          <ArgumentEditor
            v-if="argumentEditorProps"
            :userView="argumentEditorProps.userView"
            :applyArguments="argumentEditorProps.applyArguments"
            :initialArgumentsSnapshot="
              argumentEditorProps.initialArgumentsSnapshot
            "
          />
        </div>
        <div class="glass2-toolbar-right">
          <ButtonsPanel
            v-if="glass2HelpButtons.length > 0"
            :buttons="glass2HelpButtons"
            @goto="$emit('goto', $event)"
          />
          <ButtonsPanel
            v-if="glass2SecondaryButtons.length > 0"
            :buttons="glass2SecondaryButtons"
            @goto="$emit('goto', $event)"
          />
          <ButtonsPanel
            v-if="fullscreenButtons.length > 0"
            :buttons="fullscreenButtons"
            @goto="$emit('goto', $event)"
          />
          <ButtonsPanel
            :buttons="glass2ExtraButtons"
            @goto="$emit('goto', $event)"
          />
        </div>
      </div>
    </template>
    <template v-else>
      <div class="first-row">
        <div class="left-part d-flex align-items-center">
          <div v-if="$slots['left-slot']" class="left-slot">
            <slot name="left-slot" />
          </div>
          <div v-if="title && type === 'root'" class="middle-part">
            <div v-if="isLoading" class="title-placeholder" />
            <!-- `tabindex` is required for closing tooltip on blur -->
            <h1
              v-else
              v-b-tooltip.click.blur.bottom.noninteractive.viewport
              tabindex="0"
              class="userview-title"
            >
              {{ $ustOrEmpty(title) }}
            </h1>
          </div>
          <div v-else class="userview-title-wrapper">
            <div v-if="isLoading" class="title-placeholder" />
            <h2
              v-else
              v-b-tooltip.click.blur.bottom.noninteractive.viewport
              tabindex="0"
              :title="$ustOrEmpty(title)"
              class="userview-title"
            >
              {{ $ustOrEmpty(title) }}
            </h2>
          </div>
        </div>

        <div class="right-part">
          <div v-if="isLoading && type === 'root'" class="placeholder-buttons">
            <div
              v-for="index in $isMobile ? 1 : 3"
              :key="index"
              class="placeholder-button"
            />
          </div>
          <ButtonsPanel
            v-if="helpButtons.length > 0"
            :buttons="helpButtons"
            @goto="$emit('goto', $event)"
          />
          <SearchPanel
            v-if="isEnableFilter"
            class="search-panel"
            :filter-string="filterString"
            @update:filter-string="$emit('update:filter-string', $event)"
          />
          <SortEditor
            v-if="!useCompactLayout && sortEditorProps"
            :sort-editor-props="sortEditorProps"
          />
          <ArgumentEditor
            v-if="!useCompactLayout && argumentEditorProps"
            :userView="argumentEditorProps.userView"
            :applyArguments="argumentEditorProps.applyArguments"
            :initialArgumentsSnapshot="
              argumentEditorProps.initialArgumentsSnapshot
            "
          />
          <ButtonsPanel
            v-if="!useCompactLayout && headerButtons.length > 0"
            :buttons="headerButtons"
            @goto="$emit('goto', $event)"
          />
          <ButtonsPanel
            v-if="fullscreenButtons.length > 0"
            :buttons="fullscreenButtons"
            @goto="$emit('goto', $event)"
          />
          <ButtonsPanel :buttons="extraButtons" @goto="$emit('goto', $event)" />
          <div v-if="$slots['right-slot']" class="right-slot">
            <slot name="right-slot" />
          </div>
        </div>
      </div>
      <div
        v-if="
          useCompactLayout &&
          (headerButtons.length > 0 ||
            Object.keys(argumentEditorProps?.userView.argumentsMap ?? {})
              .length > 0)
        "
        class="second-row"
      >
        <ButtonsPanel
          class="second-row-button-panel"
          :buttons="headerButtons"
          @goto="$emit('goto', $event)"
        />
        <SortEditor
          v-if="sortEditorProps"
          :sort-editor-props="sortEditorProps"
        />
        <ArgumentEditor
          v-if="argumentEditorProps"
          :userView="argumentEditorProps.userView"
          :applyArguments="argumentEditorProps.applyArguments"
          :initialArgumentsSnapshot="
            argumentEditorProps.initialArgumentsSnapshot
          "
        />
      </div>
    </template>
  </div>
</template>
```

- [ ] **Step 4: TopLevelUserView.vue — pass the new props**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/TopLevelUserView.vue`, replace:

```html
        :sort-editor-props="sortEditorProps"
        :is-loading="uvLoading"
        @update:filter-string="replaceSearch({ key: null, search: $event })"
```

with:

```html
        :sort-editor-props="sortEditorProps"
        :is-loading="uvLoading"
        :icon="viewIcon"
        :description="description ?? undefined"
        :record-count="rowCount"
        @update:filter-string="replaceSearch({ key: null, search: $event })"
```

- [ ] **Step 5: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
```

Expected: `DONE No lint errors found!`. Note: eslint auto-fixes attribute order/indentation — re-stage files if it rewrites them. Do NOT build yet: the layout has no styling until Task 6; the two tasks are committed separately but checkpointed together.

- [ ] **Step 6: Commit**

```bash
git add src/components/panels/HeaderPanel.vue src/components/SearchPanel.vue src/components/TopLevelUserView.vue
git commit -m "feat(glass2): root page header and toolbar card layout"
```

---

## Task 6: Workstream C — page header + toolbar card styles

Styles the Task 5 markup in `glass2.scss` and strips the Phase 1 card chrome from the glass2 root header (row 1 sits transparent on the shell; the card look moves to the toolbar row). Existing Phase 1 rule `.header-panel.is-root` (margin/border-radius/background, glass2.scss ~line 278) is overridden by the more specific `.header-panel.is-root.glass2-root` appended later in the file. The TopLevelUserView scoped rule `.header-panel { border-bottom: … }` (specificity (0,2,0)) is also beaten by the instantiated `(1,3,0)` selectors.

**Warm-theme freeze:** CSS only, gated under the glass2 attribute selectors.

**Files:**
- Modify: `src/styles/glass2.scss` (append at end of file)

- [ ] **Step 1: Append the page-header mixin**

Append at the end of `/Users/vientooscuro/SyncFolder/ozma/src/styles/glass2.scss`:

```scss

/* ── Phase 2 §4 — root page header + toolbar card ── */
@mixin glass2-page-header {
  /* Row 1 is transparent on the shell background; the Phase 1 header-card
     chrome moves to the toolbar card below. */
  .header-panel.is-root.glass2-root {
    gap: 12px;
    margin: 0;
    border: none;
    border-radius: 0;
    box-shadow: none;
    background: transparent;
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
    padding: 14px 20px 4px;
    width: 100%;
  }

  .glass2-page-header {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
  }

  .glass2-page-header-left {
    display: flex;
    flex: 1 1 auto;
    align-items: center;
    gap: 12px;
    min-width: 0;
  }

  .glass2-icon-tile {
    display: flex;
    flex-shrink: 0;
    justify-content: center;
    align-items: center;
    border-radius: 12px;
    background: var(--accent-tint);
    width: 40px;
    height: 40px;
    color: var(--accent-300);
    font-size: 20px;
  }

  .glass2-title-block {
    min-width: 0;
  }

  .glass2-title-row {
    display: flex;
    align-items: baseline;
    gap: 10px;
  }

  .glass2-page-title {
    margin: 0;
    overflow: hidden;
    color: var(--text-primary);
    font-size: 24px;
    font-weight: 700;
    letter-spacing: -0.01em;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .glass2-record-count {
    @include glass2-mono;

    flex-shrink: 0;
    color: var(--text-muted);
    font-size: 15px;
    font-weight: 600;
  }

  .glass2-page-subtitle {
    @include glass2-microlabel;

    margin-top: 2px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .glass2-page-header-right {
    display: flex;
    flex-shrink: 0;
    align-items: center;
    gap: 10px;
  }

  /* Primary CTA: gradient pill with glow (§4 row 1 right). */
  .glass2-cta-panel .btn {
    border: none !important;
    border-radius: 999px !important;
    background: var(--gradient-accent) !important;
    box-shadow: var(--shadow-accent-glow);
    padding: 0 18px;
    height: var(--control-h-md);
    color: var(--text-on-accent) !important;
    font-weight: 600;
  }

  .glass2-cta-panel .btn:hover {
    transform: translateY(-1px);
    box-shadow: var(--shadow-accent-glow-hover);
  }

  /* Row 2 — toolbar card (§4). */
  .glass2-toolbar-card {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
    border: 1px solid var(--border-subtle);
    border-radius: 16px;
    background: var(--surface-card);
    box-shadow: var(--shadow-card);
    backdrop-filter: var(--glass-blur);
    -webkit-backdrop-filter: var(--glass-blur);
    padding: 10px 12px;
  }

  .glass2-toolbar-left,
  .glass2-toolbar-right {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .glass2-toolbar-left {
    flex: 1 1 auto;
    min-width: 0;
  }

  .glass2-toolbar-right {
    flex-shrink: 0;
  }

  /* Search as a visible ~280px inset well instead of the icon toggle. */
  .glass2-toolbar-card .search-panel .input-group {
    width: 280px;
    max-width: 100%;
  }

  .glass2-toolbar-card .search-panel .search-input {
    border-color: var(--border-default);
    background: var(--surface-inset);
  }
}

#app[data-theme-style='dark-glass'],
#app[data-theme-style='light-glass-cool'] {
  @include glass2-page-header;
}
```

- [ ] **Step 2: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint:style
```

Expected: exit 0, warnings only.

- [ ] **Step 3: Visual checkpoint (covers Tasks 4-6)**

```bash
./local_rebuild_and_publish.sh --only_ui
```

Then at `http://localhost:9080` in «dark-glass»:
1. Open a root table view. Row 1: back/home compact buttons, a 40px rounded accent-tinted tile with the view's icon (or the default table glyph), the title at 24px/700 with the record counter in muted color next to it (counter appears once all rows are counted — on partially loaded large tables it's absent by design), a caps micro-label subtitle underneath when the view has a `description` attribute. Right side: gradient CTA pill («Создать новую запись») with glow, avatar next to it (moves to the brand bar in Task 8).
2. Row 2: glass toolbar card — visible «Поиск» input (~280px, inset), sort and filter (arguments) icon buttons, secondary buttons as chips on the right, then the «⋮» menu. Typing in the search filters the table; sort/filter popovers open.
3. Click the CTA — the create flow opens exactly as the old «Создать новую запись» menu entry did.
4. Open a record form (root): same header structure; no counter; toolbar card hidden if it has no content.
5. Open the main menu screen: header renders without breakage (icon tile + title; toolbar card likely hidden).
6. Repeat 1-2 in «light-glass-cool».
7. Switch to «light-glass» (warm): header is the OLD single-row layout, search is the old icon toggle, `document.querySelectorAll('[class*="glass2-"]').length === 0` in the console.
8. Narrow the window below 480px (compact) in dark-glass: header wraps but stays usable (mobile sanity is fully verified in Task 10).

- [ ] **Step 4: Commit**

```bash
git add src/styles/glass2.scss
git commit -m "style(glass2): page header and toolbar card styles"
```

---

## Task 7: Workstream D — main-menu tabs store module

The brand bar needs the main menu's categories OUTSIDE the menu screen. `Menu.vue` gets its data as a rendered user view (`user.main` — see `homeLink` in `src/utils.ts` ~line 1085); reusing the combined-user-view store for a bar that lives on every screen is heavy. Chosen approach (sanctioned by the spec §5 "loaded once into the store and cached"): a small Vuex module that calls `api.getNamedUserView({ schema: 'user', name: 'main' })` once (same call/shape the settings module uses, `src/state/settings.ts` ~line 247), parses BOTH menu formats into flat tabs, and caches them for the session.

Parsing mirrors `Menu.vue` exactly but over the raw `IViewExprResult`:
- 1 json column ⇒ new-format menu: top-level objects with `content` become tabs (nested sub-categories are flattened into the tab's entries); top-level links become direct-navigation tabs.
- 2 columns ⇒ old-format menu: rows grouped by column 0 text; each row's link attr resolved with the same precedence `tryDicts('link', cellAttrs, columnAttrs, rowAttrs, viewAttrs)`.
- `attrToLink` opts = `{ homeSchema: 'user', defaultTarget: 'root' }` (equivalent to Menu.vue's `linkOpts` for the `user.main` view).

**Warm-theme freeze:** new module only; nothing dispatches it until Task 8 (and only in glass2).

**Files:**
- Create: `src/state/main_menu.ts`
- Modify: `src/main.ts` (import ~line 31, modules map ~line 66-78)

- [ ] **Step 1: Create the module**

Create `/Users/vientooscuro/SyncFolder/ozma/src/state/main_menu.ts`:

```ts
import { Module } from 'vuex'
import FunDBAPI, { IViewExprResult } from '@ozma-io/ozmadb-js/client'

import { IRef, mapMaybe, tryDicts, waitTimeout } from '@/utils'
import { CancelledError } from '@/modules'
import { Link, attrToLink, IAttrToLinkOpts } from '@/links'
import { rawToUserString, UserString } from '@/state/translations'
import { valueToPunnedText } from '@/user_views/combined'

// Brand-bar tabs (Phase 2 §5): one tab per main-menu category. Loaded once
// from the same user view the menu screen renders (user.main) and cached
// for the session.

export interface IBrandBarEntry {
  name: UserString
  link: Link
}

export interface IBrandBarTab {
  name: UserString
  // Category entries shown in the tab dropdown. Empty for loose top-level
  // links, which navigate directly via `directLink`.
  entries: IBrandBarEntry[]
  directLink: Link | null
}

// Same options Menu.vue uses for the user.main view (homeSchema comes from
// the named ref's schema).
const linkOpts: IAttrToLinkOpts = {
  homeSchema: 'user',
  defaultTarget: 'root',
}

// Flatten a category's content into link entries (sub-categories are
// flattened — the bar has a single dropdown level).
const collectEntries = (content: unknown[]): IBrandBarEntry[] => {
  return content.flatMap((rawEntry) => {
    if (typeof rawEntry !== 'object' || rawEntry === null) return []
    const entry = rawEntry as Record<string, unknown>
    const name = rawToUserString(entry.name)
    if (name === null) return []
    if ('content' in entry) {
      return entry.content instanceof Array ? collectEntries(entry.content) : []
    }
    const link = attrToLink(entry, linkOpts)
    if (link === null) return []
    return [{ name, link }]
  })
}

// New-format menu: single json column, one menu object/array per row
// (mirrors Menu.vue's buildNewMenu/convertNewMenuEntry).
const parseNewMenu = (res: IViewExprResult): IBrandBarTab[] => {
  return res.result.rows.flatMap((row) => {
    const rawMenu = row.values[0].value
    const rawEntries =
      rawMenu instanceof Array
        ? rawMenu
        : typeof rawMenu === 'object' && rawMenu !== null
          ? [rawMenu]
          : []
    return mapMaybe((rawEntry: unknown): IBrandBarTab | undefined => {
      if (typeof rawEntry !== 'object' || rawEntry === null) return undefined
      const entry = rawEntry as Record<string, unknown>
      const name = rawToUserString(entry.name)
      if (name === null) return undefined
      if ('content' in entry) {
        if (!(entry.content instanceof Array)) return undefined
        return { name, entries: collectEntries(entry.content), directLink: null }
      }
      const link = attrToLink(entry, linkOpts)
      if (link === null) return undefined
      return { name, entries: [], directLink: link }
    }, rawEntries)
  })
}

// Old-format menu: two columns (category, button), grouped by category text
// (mirrors Menu.vue's buildOldMenu, including the link-attr precedence).
const parseOldMenu = (res: IViewExprResult): IBrandBarTab[] => {
  const categoryType = res.info.columns[0].valueType
  const buttonType = res.info.columns[1].valueType
  const viewAttrs = res.result.attributes
  const buttonsColumnAttrs = res.result.columnAttributes[1]

  const categories = new Map<string, IBrandBarEntry[]>()
  res.result.rows.forEach((row) => {
    const categoryName = valueToPunnedText(categoryType, row.values[0])
    let entries = categories.get(categoryName)
    if (entries === undefined) {
      entries = []
      categories.set(categoryName, entries)
    }

    const buttonCell = row.values[1]
    const buttonName = valueToPunnedText(buttonType, buttonCell)
    const linkAttr = tryDicts(
      'link',
      buttonCell.attributes,
      buttonsColumnAttrs,
      row.attributes,
      viewAttrs,
    )
    const link = attrToLink(linkAttr, linkOpts)
    if (link === null) return
    entries.push({ name: buttonName, link })
  })

  return Array.from(categories.entries()).map(([name, entries]) => ({
    name,
    entries,
    directLink: null,
  }))
}

export interface IMainMenuState {
  tabs: IBrandBarTab[] | null
  pending: Promise<IBrandBarTab[]> | null
}

const mainMenuModule: Module<IMainMenuState, {}> = {
  namespaced: true,
  state: {
    tabs: null,
    pending: null,
  },
  mutations: {
    setTabs: (state, tabs: IBrandBarTab[]) => {
      state.tabs = tabs
      state.pending = null
    },
    setPending: (state, pending: Promise<IBrandBarTab[]> | null) => {
      state.pending = pending
    },
    clearTabs: (state) => {
      state.tabs = null
      state.pending = null
    },
  },
  actions: {
    getMainMenu: ({ state, commit, dispatch }): Promise<IBrandBarTab[]> => {
      if (state.tabs !== null) {
        return Promise.resolve(state.tabs)
      }
      if (state.pending !== null) {
        return state.pending
      }
      const pending: IRef<Promise<IBrandBarTab[]>> = {}
      pending.ref = (async () => {
        await waitTimeout() // Delay so the promise gets saved to `pending` first.
        try {
          const res = (await dispatch(
            'callApi',
            {
              func: (api: FunDBAPI) =>
                api.getNamedUserView({ schema: 'user', name: 'main' }),
            },
            { root: true },
          )) as IViewExprResult
          if (state.pending !== pending.ref) {
            throw new CancelledError()
          }
          const tabs =
            res.info.columns.length === 1
              ? parseNewMenu(res)
              : res.info.columns.length === 2
                ? parseOldMenu(res)
                : []
          commit('setTabs', tabs)
          return tabs
        } catch (e) {
          if (state.pending === pending.ref) {
            commit('clearTabs')
          }
          throw e
        }
      })()
      commit('setPending', pending.ref)
      return pending.ref
    },
  },
}

export default mainMenuModule
```

- [ ] **Step 2: Register the module**

In `/Users/vientooscuro/SyncFolder/ozma/src/main.ts`, replace:

```ts
import translationsModule from '@/state/translations'
```

with:

```ts
import translationsModule from '@/state/translations'
import mainMenuModule from '@/state/main_menu'
```

and replace:

```ts
    windows: windowsModule,
    translations: translationsModule,
  },
})
```

with:

```ts
    windows: windowsModule,
    translations: translationsModule,
    mainMenu: mainMenuModule,
  },
})
```

- [ ] **Step 3: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
```

Expected: `DONE No lint errors found!` (the module has no consumer yet — that's fine, exports are used in Task 8; if eslint flags nothing-imported it doesn't, since main.ts imports it).

- [ ] **Step 4: Commit**

```bash
git add src/state/main_menu.ts src/main.ts
git commit -m "feat: main menu tabs store module"
```

---

## Task 8: Workstream D — BrandBar component, mount, avatar move

New `src/components/BrandBar.vue` per §5: brand tile + instance name (settings key `brand_title`, fallback «Ozma»), one tab per category (Popper dropdown with the category's entries, same links as the menu screen), theme quick-toggle (sun/moon between the two glass2 themes, sibling ref resolved from the themes map — never hardcode the schema), and the ProfileButton avatar moved out of the header. Mounted in `TopLevelUserView.vue` above `.userview-upper-div`, glass2-gated.

Verified integration points:
- Popper usage pattern: `src/components/ProfileButton.vue` (~lines 103-146) — `trigger="clickToOpen"`, `:disabled`/`:force-show` + `@document-click`, `slot="reference"` with an eslint-disable for the deprecated slot attribute.
- `ButtonList` (`src/components/buttons/ButtonList.vue`) renders `Button[]` vertically and re-emits `goto` — dropdown entries become `{ type: 'link', caption, variant: defaultVariantAttribute, link }`.
- Active tab: current root view ref from the query store (`query.root.args.source`, type `'named'` ⇒ `ref.schema/name`) matched against entry links (`IQueryLink` with a named source). No match ⇒ no active tab (spec §8 accepts this).
- Theme sibling: `settings.current.themes` is `ThemesMap = Record<SchemaName, Record<ThemeName, ITheme>>`; prefer the current ref's schema, else any schema containing the sibling name; hide the toggle if not installed. Dispatch the existing `settings/setCurrentTheme` action with the resolved `IThemeRef`.
- `$isMobile` is a global mixin; on mobile the bar shows brand + toggle + avatar only (tabs hidden).

**Warm-theme freeze:** BrandBar renders only under `v-if="showBrandBar"` (glass2); the header ProfileButton wrapper gets `v-if="!showBrandBar"`, which is `true` for warm themes ⇒ identical warm DOM (a v-if comment placeholder is style-invisible, per spec §7.3 fingerprint methodology).

**Files:**
- Create: `src/components/BrandBar.vue`
- Modify: `src/components/TopLevelUserView.vue` (template: mount + avatar v-if; script: import/component/state/getter)

- [ ] **Step 1: Create BrandBar.vue**

Create `/Users/vientooscuro/SyncFolder/ozma/src/components/BrandBar.vue`:

```vue
<i18n>
  {
    "en": {
      "toggle_theme": "Switch theme"
    },
    "ru": {
      "toggle_theme": "Переключить тему"
    },
    "es": {
      "toggle_theme": "Cambiar el tema"
    }
  }
</i18n>

<template>
  <header class="glass2-brand-bar">
    <OzmaLink
      class="glass2-brand"
      :link="homeLink"
      @goto="$emit('goto', $event)"
    >
      <span class="glass2-brand-tile">{{ brandInitial }}</span>
      <span v-if="!$isMobile" class="glass2-brand-name">{{ brandTitle }}</span>
    </OzmaLink>

    <nav v-if="!$isMobile" class="glass2-brand-tabs">
      <template v-for="(tab, tabI) in tabs">
        <OzmaLink
          v-if="tab.directLink"
          :key="'direct' + tabI"
          class="glass2-brand-tab"
          :link="tab.directLink"
          @goto="$emit('goto', $event)"
        >
          {{ $ustOrEmpty(tab.name) }}
        </OzmaLink>
        <popper
          v-else
          :key="'tab' + tabI"
          trigger="clickToOpen"
          transition="ozma-popover"
          enter-active-class="ozma-popover-enter-active"
          leave-active-class="ozma-popover-leave-active"
          :visible-arrow="false"
          :options="{
            placement: 'bottom-start',
            positionFixed: true,
            modifiers: {
              offset: { offset: '0, 8' },
              preventOverflow: { enabled: true, boundariesElement: 'viewport' },
              hide: { enabled: true },
            },
          }"
          :disabled="openTabIndex !== tabI"
          :force-show="openTabIndex === tabI"
          @document-click="closeTab(tabI)"
        >
          <div class="popper glass2-brand-dropdown">
            <ButtonList :buttons="tabButtons(tab)" @goto="onEntryGoto" />
          </div>
          <!-- eslint-disable vue/no-deprecated-slot-attribute -->
          <button
            slot="reference"
            type="button"
            :class="['glass2-brand-tab', { active: tabI === activeTabIndex }]"
            @click.capture="toggleTab(tabI)"
          >
            {{ $ustOrEmpty(tab.name) }}
            <AppIcon class="glass2-brand-tab-chevron" name="expand_more" />
          </button>
          <!-- eslint-enable vue/no-deprecated-slot-attribute -->
        </popper>
      </template>
    </nav>

    <div class="glass2-brand-right">
      <button
        v-if="siblingThemeRef"
        type="button"
        class="glass2-theme-toggle"
        :aria-label="$t('toggle_theme').toString()"
        @click="switchTheme"
      >
        <AppIcon :name="themeToggleIcon" />
      </button>
      <ProfileButton @goto="$emit('goto', $event)" />
    </div>
  </header>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'
import { namespace } from 'vuex-class'
import Popper from '@/components/common/OzmaPopper.vue'

import { homeLink } from '@/utils'
import { defaultVariantAttribute } from '@/utils_colors'
import type { IThemeRef } from '@/utils_colors'
import type { Button } from '@/components/buttons/buttons'
import type { IBrandBarTab } from '@/state/main_menu'
import { CurrentSettings } from '@/state/settings'
import type { ICurrentQueryHistory } from '@/state/query'
import type { IUserViewRef } from '@ozma-io/ozmadb-js/client'
import ButtonList from '@/components/buttons/ButtonList.vue'
import ProfileButton from '@/components/ProfileButton.vue'

const settings = namespace('settings')
const query = namespace('query')
const mainMenu = namespace('mainMenu')

// Brand bar (Phase 2 §5): rendered by TopLevelUserView in glass2 themes
// only. Brand + main-menu category tabs + theme quick-toggle + avatar.
@Component({ components: { ButtonList, ProfileButton, Popper } })
export default class BrandBar extends Vue {
  @settings.State('current') currentSettings!: CurrentSettings
  @settings.State('currentThemeRef') currentThemeRef!: IThemeRef | null
  @settings.Action('setCurrentTheme') setCurrentTheme!: (
    theme: IThemeRef,
  ) => Promise<void>
  @query.State('current') query!: ICurrentQueryHistory | null
  @mainMenu.State('tabs') storeTabs!: IBrandBarTab[] | null
  @mainMenu.Action('getMainMenu') getMainMenu!: () => Promise<IBrandBarTab[]>

  private openTabIndex: number | null = null
  private homeLink = homeLink

  mounted() {
    // Fire-and-forget: an unavailable menu just means no tabs.
    void this.getMainMenu().catch(() => {})
  }

  get tabs(): IBrandBarTab[] {
    return this.storeTabs ?? []
  }

  get brandTitle(): string {
    return this.currentSettings.getEntry('brand_title', String, 'Ozma')
  }

  get brandInitial(): string {
    return this.brandTitle.charAt(0).toUpperCase()
  }

  private get currentViewRef(): IUserViewRef | null {
    const source = this.query?.root.args.source
    if (source && source.type === 'named') {
      return source.ref
    }
    return null
  }

  // Active tab: the category containing a link to the current named view.
  // Heuristic per §8 — unmatched views simply have no active tab.
  get activeTabIndex(): number | null {
    const current = this.currentViewRef
    if (current === null) return null
    const index = this.tabs.findIndex((tab) =>
      tab.entries.some(
        (entry) =>
          entry.link.type === 'query' &&
          entry.link.query.args.source.type === 'named' &&
          entry.link.query.args.source.ref.schema === current.schema &&
          entry.link.query.args.source.ref.name === current.name,
      ),
    )
    return index === -1 ? null : index
  }

  // Sibling glass2 theme for the quick-toggle: same schema preferred, any
  // schema as fallback, hidden when the sibling isn't installed. The schema
  // MUST come from the themes map (instances differ) — never hardcoded.
  get siblingThemeRef(): IThemeRef | null {
    const current = this.currentThemeRef
    if (current === null) return null
    const targetName =
      current.name === 'dark-glass' ? 'light-glass-cool' : 'dark-glass'
    const themes = this.currentSettings.themes
    if (themes[current.schema]?.[targetName] !== undefined) {
      return { schema: current.schema, name: targetName }
    }
    const fallback = Object.entries(themes).find(
      ([, schemaThemes]) => targetName in schemaThemes,
    )
    return fallback ? { schema: fallback[0], name: targetName } : null
  }

  get themeToggleIcon(): string {
    return this.currentThemeRef?.name === 'dark-glass'
      ? 'light_mode'
      : 'dark_mode'
  }

  private switchTheme() {
    if (this.siblingThemeRef) {
      void this.setCurrentTheme(this.siblingThemeRef)
    }
  }

  private tabButtons(tab: IBrandBarTab): Button[] {
    return tab.entries.map(
      (entry): Button => ({
        type: 'link',
        caption: entry.name,
        variant: defaultVariantAttribute,
        link: entry.link,
      }),
    )
  }

  private toggleTab(tabI: number) {
    this.openTabIndex = this.openTabIndex === tabI ? null : tabI
  }

  private closeTab(tabI: number) {
    if (this.openTabIndex === tabI) {
      this.openTabIndex = null
    }
  }

  private onEntryGoto(event: unknown) {
    this.openTabIndex = null
    this.$emit('goto', event)
  }
}
</script>
```

(No `<style>` block — all styling is global in glass2.scss, Task 9, because the bar only exists in glass2 themes.)

- [ ] **Step 2: Mount in TopLevelUserView.vue**

In `/Users/vientooscuro/SyncFolder/ozma/src/components/TopLevelUserView.vue`, template, replace:

```html
    <div :class="'userview-upper-div'">
      <HeaderPanel
```

with:

```html
    <BrandBar v-if="showBrandBar" @goto="push({ ...$event, key: null })" />

    <div :class="'userview-upper-div'">
      <HeaderPanel
```

Then move the avatar (§4/§5): replace:

```html
        <template #right-slot>
          <div class="profile-button-wrapper">
            <ProfileButton />
          </div>
        </template>
```

with:

```html
        <template #right-slot>
          <div v-if="!showBrandBar" class="profile-button-wrapper">
            <ProfileButton />
          </div>
        </template>
```

In the script, replace:

```ts
import ProfileButton from './ProfileButton.vue'
import AlertBanner from './AlertBanner.vue'
```

with:

```ts
import ProfileButton from './ProfileButton.vue'
import AlertBanner from './AlertBanner.vue'
import BrandBar from './BrandBar.vue'
import { isGlass2Theme } from '@/utils/glass2'
import type { IThemeRef } from '@/utils_colors'
```

Replace the components map:

```ts
@Component({
  components: {
    ModalUserView,
    ProgressBar,
    QRCodeScannerModal,
    HeaderPanel,
    ProfileButton,
    AlertBanner,
  },
```

with:

```ts
@Component({
  components: {
    ModalUserView,
    ProgressBar,
    QRCodeScannerModal,
    HeaderPanel,
    ProfileButton,
    AlertBanner,
    BrandBar,
  },
```

And add the state binding + getter — replace:

```ts
  @settings.State('current') currentSettings!: CurrentSettings
```

with:

```ts
  @settings.State('current') currentSettings!: CurrentSettings
  @settings.State('currentThemeRef') currentThemeRef!: IThemeRef | null
```

then, after the `navigationButtons` getter (its closing `}` before `get titleOrNewEntry()`), add:

```ts
  get showBrandBar(): boolean {
    return isGlass2Theme(this.currentThemeRef)
  }
```

- [ ] **Step 3: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
```

Expected: `DONE No lint errors found!`. The bar is unstyled until Task 9 — checkpoint happens there.

- [ ] **Step 4: Commit**

```bash
git add src/components/BrandBar.vue src/components/TopLevelUserView.vue
git commit -m "feat(glass2): brand bar with menu tabs and theme toggle"
```

---

## Task 9: Workstream D — brand bar styles + shell layout ladder

Styles the bar and fixes the shell flex layout (`.userview-upper-div` has `height: inherit` in TopLevelUserView's scoped CSS — with a 52px sibling above it the column would overflow; the glass2 override switches it to `flex: 1`). All rules instantiate under `#app[data-theme-style=…]` (specificity (1,3,0)) and therefore beat the scoped component rules ((0,2,0)).

**Warm-theme freeze:** CSS only, glass2-gated.

**Files:**
- Modify: `src/styles/glass2.scss` (append at end of file)

- [ ] **Step 1: Append the brand-bar mixin**

Append at the end of `/Users/vientooscuro/SyncFolder/ozma/src/styles/glass2.scss`:

```scss

/* ── Phase 2 §5 — brand bar + shell layout ──
   Z-ladder (top → bottom): overlays/modals 100050 (glass2-overlays) >
   brand bar 120 > sticky root header 100 (glass2-header) > table fixed
   cells 0–1 (glass2-table-fixed). The bar itself is a static flex row —
   the page scroll container is .userview-div, so nothing scrolls past it. */
@mixin glass2-brand-bar {
  .glass2-brand-bar {
    display: flex;
    position: relative;
    flex: 0 0 auto;
    align-items: center;
    gap: 16px;
    z-index: 120;
    border-bottom: 1px solid var(--border-subtle);
    background: var(--surface-card);
    backdrop-filter: var(--glass-blur);
    -webkit-backdrop-filter: var(--glass-blur);
    padding: 0 20px;
    height: 52px;
  }

  /* Shell fix: .userview-upper-div inherits 100% height (scoped CSS in
     TopLevelUserView); with the 52px bar above it must flex instead. */
  .main-div > .userview-upper-div {
    flex: 1 1 0;
    height: auto;
    min-height: 0;
  }

  .glass2-brand {
    display: flex;
    flex-shrink: 0;
    align-items: center;
    gap: 10px;
    text-decoration: none;
  }

  .glass2-brand:hover {
    text-decoration: none;
  }

  .glass2-brand-tile {
    display: flex;
    justify-content: center;
    align-items: center;
    border-radius: 9px;
    background: var(--gradient-accent);
    box-shadow: var(--shadow-accent-glow);
    width: 28px;
    height: 28px;
    color: var(--text-on-accent);
    font-size: 14px;
    font-weight: 800;
  }

  .glass2-brand-name {
    color: var(--text-primary);
    font-size: 15px;
    font-weight: 700;
    letter-spacing: -0.01em;
    white-space: nowrap;
  }

  /* 9+ categories: horizontal scroll, no wrapping, hidden scrollbar. */
  .glass2-brand-tabs {
    display: flex;
    flex: 1 1 auto;
    align-items: center;
    gap: 4px;
    min-width: 0;
    overflow-x: auto;
    scrollbar-width: none;
  }

  .glass2-brand-tabs::-webkit-scrollbar {
    display: none;
  }

  .glass2-brand-tab {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    cursor: pointer;
    border: none;
    border-radius: 999px;
    background: transparent;
    padding: 7px 12px;
    color: var(--text-secondary);
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    white-space: nowrap;
  }

  .glass2-brand-tab:hover {
    background: var(--surface-hover);
    color: var(--text-primary);
    text-decoration: none;
  }

  .glass2-brand-tab.active {
    background: var(--accent-tint);
    color: var(--accent-300);
  }

  .glass2-brand-tab-chevron {
    font-size: 14px;
    opacity: 0.7;
  }

  .glass2-brand-dropdown {
    min-width: 220px;
  }

  .glass2-brand-right {
    display: flex;
    flex-shrink: 0;
    align-items: center;
    gap: 10px;
    margin-left: auto;
  }

  .glass2-theme-toggle {
    display: flex;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    border: 1px solid var(--border-default);
    border-radius: 10px;
    background: transparent;
    width: 34px;
    height: 34px;
    color: var(--text-secondary);
    font-size: 16px;
  }

  .glass2-theme-toggle:hover {
    background: var(--surface-hover);
    color: var(--text-primary);
  }

  /* Avatar keeps the Phase 1 gradient-tile treatment in its new home. */
  .glass2-brand-bar .avatar-box .placeholder-avatar {
    background: var(--gradient-accent) !important;
    border-radius: 12px !important;
    color: var(--text-on-accent);
  }
}

#app[data-theme-style='dark-glass'],
#app[data-theme-style='light-glass-cool'] {
  @include glass2-brand-bar;
}
```

- [ ] **Step 2: Lint**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint:style
```

Expected: exit 0, warnings only.

- [ ] **Step 3: Visual checkpoint (covers Tasks 7-9)**

```bash
./local_rebuild_and_publish.sh --only_ui
```

Then at `http://localhost:9080` in «dark-glass»:
1. Every root screen shows the 52px brand bar on top: gradient mini-tile with the instance's first letter + instance name (from `funapp.settings.brand_title`, «Ozma» if unset), category tabs, sun/moon toggle, avatar on the right. The page header row below has NO avatar anymore.
2. Click a category tab — a glass dropdown opens with the category's entries (same links as the menu screen); clicking an entry navigates and closes the dropdown. The dropdown renders ABOVE the page header/toolbar (z-ladder).
3. Open a view that is listed in the menu: its category tab is the accent-tinted pill. Open a view not in the menu (e.g. a system view): no active tab.
4. Click the sun/moon toggle: theme flips dark-glass ↔ light-glass-cool instantly (brand bar and all glass2 layouts stay; the toggle icon flips). Toggle back.
5. Home button in the page header still reaches the main menu screen.
6. No vertical overflow: the window shows brand bar + header + content with the ONLY scrollbar inside the table area; the save-cluster buttons (bottom right) are visible.
7. Switch to «light-glass» (warm): NO brand bar, avatar back in the header, `document.querySelectorAll('[class*="glass2-"]').length === 0`.
8. Mobile viewport (≤480px width) in dark-glass: bar shows tile + toggle + avatar (no tabs, no name).

- [ ] **Step 4: Commit**

```bash
git add src/styles/glass2.scss
git commit -m "style(glass2): brand bar styles and shell layout"
```

---

## Task 10: Final verification (spec §7)

No code changes expected; fix-forward any findings (small fixes amend into a new commit `fix(glass2): shell sync review fixes`).

- [ ] **Step 1: Full lint + build gate**

```bash
cd /Users/vientooscuro/SyncFolder/ozma
YARN_NODE_LINKER=node-modules yarn lint
YARN_NODE_LINKER=node-modules yarn lint:style
./local_rebuild_and_publish.sh --only_ui
```

Expected: `DONE No lint errors found!`; stylelint exit 0; build succeeds.

- [ ] **Step 2: §7.1 — side-by-side with the reference**

Serve the mockup: `python3 -m http.server 8899 --directory "/Users/vientooscuro/Downloads/Новый дизайн экранов"` and open the CRM «Студенты» ui-kit screen (`_ds/*/ui_kits/crm`). Next to it, open a students-like root table view at `http://localhost:9080` in «dark-glass». Compare structurally (not pixel-perfect): brand bar (tile + name + tabs + toggle + avatar) / page header (icon tile, 24px title + counter, caps subtitle, gradient CTA right) / toolbar card (visible search well, sort + filter icon buttons, chips, ⋮) / table (bold first column, boolean check squares, chips, mono phones/dates) / footer (`НАЗАД 1 2 3 … N ВПЕРЕД` with accent pill on the current page).

- [ ] **Step 3: §7.2 — both new themes × 4 screens**

For each of «dark-glass» and «light-glass-cool» check: (a) main menu screen, (b) a table view, (c) a record form, (d) the Monaco editor (development mode → edit view). Look for: no layout breakage from the two new bars, sticky table headers still stick below the page header, modals open above everything (open a record in a modal), popovers (sort/filter/profile/tab dropdowns) not clipped, no unexpected page-level scrollbar.

- [ ] **Step 4: §7.3 — warm-theme DOM-identity regression**

In «light-glass» on the reference screens (menu, table, form):
1. `document.querySelectorAll('[class*="glass2-"]').length` → `0` on every screen.
2. The header is the legacy single-row layout with the avatar in it; search is the icon toggle; pagination is the legacy arrows + `1/N` pill; no brand bar.
3. Computed-style fingerprint spot-check: for `.header-panel`, `.pagination`, `.custom-table tbody td:nth-child(3)` compare `getComputedStyle(el).cssText` visually against the pre-Phase-2 master build if available (or at minimum confirm fonts/colors/weights match the warm screenshots taken during Phase 1). Also check the default (non-glass) theme briefly if the instance has one.

- [ ] **Step 5: §7.4 — mobile sanity**

Device-emulation viewport (~390×844) in both new themes: brand bar collapses to tile + toggle + avatar; page header wraps without horizontal scroll; toolbar card wraps; table scrolls horizontally as before; numbered pagination wraps acceptably in the footer.

- [ ] **Step 6: Push the branch**

```bash
git log --oneline -12   # review: one commit per task, imperative titles
git push origin glass-themes-2
```

---

## Appendix — deviations from the spec (with rationale)

1. **§2.3 empty-value dash is limited to null-boolean cells.** Text cells always render `<span class="text" v-html="valueHtml || '&nbsp;'"/>` (TableCell.vue line 129), so `:empty` can never match them; the spec's own escape hatch («dropped silently for cell types where markup never renders empty») applies. Doing better would require a theme-gated class on every TableCell (hot component, thousands of instances) — rejected as risk/benefit-negative for Phase 2.
2. **§4 record counter and icon need two new events** (`update:row-count`, `update:icon`) along the existing `Table → UserView → TopLevelUserView` event chain, despite the §4 note "no new data plumbing" (which is honored for buttons/search). Events are DOM-invisible and theme-neutral; without them the counter/icon are impossible. Additionally the counter (and the last page number in §3's pager) only appear once `rowLoadState.complete` is true — on large lazily-loaded tables the total is genuinely unknown until all rows are fetched, so the tail shows an open «…» and no counter. This matches the data model, not a bug.
3. **§3 numbered pagination applies to nested-view tables too** (the gate is the theme, not `isTopLevel`) — consistent UX; the spec only explicitly discusses the root footer.
4. **§2.2 radius 6 via CSS `rx`** on the SVG rect: honored by Chromium/Firefox; older Safari keeps the baked-in `rx=4` attribute (visually near-identical, graceful degradation).
5. **§4 CTA caption** is the existing «Создать новую запись» (UserViewCommon's `create` i18n key), not the reference's «Новая запись» — reusing the existing button model verbatim per §4 ("reusing the existing buttons/search models").
6. **§5 loose top-level menu links** (new-format menus can have links outside any category) become direct-navigation tabs without a dropdown; nested sub-categories are flattened into their parent tab's dropdown (the bar has one dropdown level).
7. **§5 theme quick-toggle hides itself** when the sibling glass2 theme is not installed in the instance's themes map (instead of dispatching a ref that `getSettings` would reject).
8. **§5 tab data loader**: implemented as a dedicated Vuex module over the raw `getNamedUserView` result (the alternative sanctioned in the planning brief), NOT by reusing the combined-user-view store — the menu parsing logic is mirrored from Menu.vue for both menu formats; Menu.vue itself is untouched (zero risk to the menu screen in all themes).
9. **§5 "fixed top bar"** is implemented as a static flex row, not `position: fixed` — the app's scroll container is `.userview-div`, so the bar can never scroll out of view; `position: fixed` would only add offset bookkeeping for zero visual difference.
