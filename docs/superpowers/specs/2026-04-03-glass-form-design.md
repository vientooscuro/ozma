# Glass Form Design — Spec

**Date:** 2026-04-03  
**Scope:** Only glass themes (`dark-glass`, `light-glass-warm`). Default themes are not touched. `light-glass-cool` removed from scope.  
**Components:** All form elements — inputs, textareas, labels, section cards, indicators, buttons.

---

## 1. Themes Overview

Two glass themes applied via CSS class on the theme root element. The existing theme switching mechanism is preserved — only CSS variable values and SCSS blocks change.

| Theme | Class | Description |
|-------|-------|-------------|
| Dark Glass | `dark-glass` | Deep navy, teal accent, intense glass |
| Light Glass Warm | `light-glass-warm` | Aivazovsky sea palette, warm amber background, liquid glass |

---

## 2. Dark Glass

### Background
```css
background: linear-gradient(145deg, #020810 0%, #07121f 60%, #040c14 100%);
```
Ambient orbs (pseudo-elements on form container or `<body>`):
- Top-right: `rgba(89,214,207,0.07)` 300×300px `blur(80px)`
- Bottom-left: `rgba(15,118,110,0.09)` 250×250px `blur(70px)`

### Form card (`.form_sub_block`, `.first_level_grid_block`)
```css
background: rgba(255,255,255,0.07);
backdrop-filter: blur(24px) saturate(180%);
-webkit-backdrop-filter: blur(24px) saturate(180%);
border: 1px solid rgba(255,255,255,0.14);
border-radius: 18px;
box-shadow: 0 16px 48px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.1);
```

### Input / Textarea fields
```css
/* default */
background: rgba(255,255,255,0.05);
border: 1px solid rgba(255,255,255,0.10);
border-radius: 10px;
box-shadow: 0 2px 8px rgba(0,0,0,0.15);

/* :focus */
border-color: rgba(89,214,207,0.5);
background: rgba(255,255,255,0.08);
box-shadow: 0 0 0 3px rgba(89,214,207,0.12), 0 2px 8px rgba(0,0,0,0.15);
```

### Field gap
```css
gap: 8px; /* between field rows inside a card */
```

### Floating label / field label
```css
font-family: 'Space Grotesk', sans-serif;
font-size: 9px; font-weight: 700;
letter-spacing: 0.1em; text-transform: uppercase;
color: rgba(255,255,255,0.35);        /* default */
color: rgba(89,214,207,0.70);         /* accent/focused */
```

### Section title
```css
font-family: 'Space Grotesk', sans-serif;
font-size: 9px; font-weight: 700; letter-spacing: 0.14em; text-transform: uppercase;
color: rgba(89,214,207,0.6);
```

### Required indicator
```css
width: 5px; height: 5px; border-radius: 50%;
background: rgba(255,120,100,0.8);
box-shadow: 0 0 6px rgba(255,120,100,0.5);
```

### Primary button (Save)
```css
background: linear-gradient(135deg, rgba(89,214,207,0.25), rgba(15,118,110,0.25));
border: 1.5px solid rgba(89,214,207,0.5);
color: #59d6cf;
border-radius: 999px;
box-shadow: 0 0 20px rgba(89,214,207,0.18), inset 0 1px 0 rgba(255,255,255,0.08);
```

### Danger button (Delete)
```css
background: transparent;
border: 1px solid rgba(255,80,60,0.25);
color: rgba(255,120,100,0.7);
border-radius: 999px;
```

### CSS variable overrides
```css
--cell-borderColor: rgba(255,255,255,0.10);
--cell-backgroundColor: rgba(255,255,255,0.05);
--cell-foregroundColor: #e7ecef;
--cell-foregroundDarkerColor: rgba(255,255,255,0.22);
--default-backgroundColor: rgba(255,255,255,0.07);
--default-borderColor: rgba(255,255,255,0.14);
--default-foregroundColor: #e7ecef;
--default-foregroundDarkerColor: rgba(255,255,255,0.35);
--FocusBorderColor: rgba(89,214,207,0.5);
--radius-input: 10px;
--MainTextColor: #e7ecef;
--MainTextColorLight: rgba(255,255,255,0.22);
```

---

## 3. Light Glass Warm — Aivazovsky Sea

Palette inspired by Aivazovsky seascapes: deep navy-teal → wave → bright crest.

### Background
```css
background: #f6f4ef;
background-image:
  radial-gradient(ellipse 55% 38% at 8%  0%,  rgba(255,249,226,0.9)  0%, transparent 65%),
  radial-gradient(ellipse 40% 30% at 75% 5%,  rgba(219,248,240,0.7)  0%, transparent 60%),
  radial-gradient(ellipse 35% 25% at 40% 80%, rgba(243,234,214,0.5)  0%, transparent 55%),
  radial-gradient(ellipse 30% 20% at 95% 70%, rgba(232,249,255,0.42) 0%, transparent 50%);
```
Ambient orbs:
- Top-left amber: `rgba(255,249,226,0.75)` 340×340px `blur(90px)`
- Bottom-right sea: `rgba(219,248,240,0.6)` 280×280px `blur(80px)`

### Colour palette
| Name | Value | Usage |
|------|-------|-------|
| `--sea-deep` | `#1a5f7a` | section titles, link colour |
| `--sea-mid` | `#2185a0` | button gradient middle |
| `--sea-bright` | `#3db8c8` | button gradient start, focus ring base |
| `--sea-foam` | `rgba(143,214,228,0.45)` | field border default |

### Form card
```css
background: rgba(255,255,255,0.42);
backdrop-filter: blur(40px) saturate(180%) brightness(1.03);
-webkit-backdrop-filter: blur(40px) saturate(180%) brightness(1.03);
border: 1px solid rgba(255,255,255,0.75);
border-radius: 20px;
box-shadow: 0 16px 48px rgba(28,23,15,0.09),
            0 0 40px rgba(246,185,65,0.08),
            inset 0 1px 0 rgba(255,255,255,0.9);
```

### Input / Textarea fields
```css
/* default */
background: rgba(255,255,255,0.38);
border: 1px solid rgba(143,214,228,0.45);
border-radius: 12px;
box-shadow: inset 0 1px 0 rgba(255,255,255,0.85), 0 1px 4px rgba(28,23,15,0.05);

/* :focus */
border-color: rgba(33,133,160,0.5);
background: rgba(220,244,248,0.55);
box-shadow: 0 0 0 3px rgba(61,184,200,0.15),
            inset 0 1px 0 rgba(255,255,255,0.9),
            0 1px 4px rgba(28,23,15,0.05);
```

### Field gap
```css
gap: 8px;
```

### Floating label / field label
```css
font-family: 'Space Grotesk', sans-serif;
font-size: 9px; font-weight: 700;
letter-spacing: 0.1em; text-transform: uppercase;
color: #6f6a62;       /* default/muted */
color: #1a5f7a;       /* accent */
```

### Section title
```css
color: #1a5f7a;
```

### Required indicator
```css
background: rgba(220,80,60,0.7);
box-shadow: 0 0 5px rgba(220,80,60,0.28);
```

### Primary button (Save)
```css
background: linear-gradient(135deg, #3db8c8 0%, #2185a0 50%, #1a5f7a 100%);
color: #fff;
border-radius: 999px;
box-shadow: 0 4px 18px rgba(33,133,160,0.35), 0 0 24px rgba(61,184,200,0.15);
```

### Danger button (Delete)
```css
background: transparent;
border: 1px solid rgba(220,60,40,0.2);
color: rgba(200,60,40,0.6);
border-radius: 999px;
```

### CSS variable overrides
```css
--cell-borderColor: rgba(143,214,228,0.45);
--cell-backgroundColor: rgba(255,255,255,0.38);
--cell-foregroundColor: #1f1f1f;
--cell-foregroundDarkerColor: rgba(111,106,98,0.38);
--default-backgroundColor: rgba(255,255,255,0.42);
--default-borderColor: rgba(255,255,255,0.75);
--default-foregroundColor: #1f1f1f;
--default-foregroundDarkerColor: #6f6a62;
--FocusBorderColor: rgba(33,133,160,0.5);
--radius-input: 12px;
--MainTextColor: #1f1f1f;
--MainTextColorLight: rgba(111,106,98,0.38);
```

---

## 4. Shared Changes (both glass themes)

### Typography for labels
All glass themes use `'Space Grotesk'` for floating labels and section titles — already bundled via `@fontsource/space-grotesk`.

### Button border-radius
Both glass themes use `border-radius: 999px` (pill) for action buttons.

### Field gap
Both themes use `gap: 8px` between field rows inside cards.

### Disabled indicator
Glass themes show the `edit_off` material icon with `opacity: 0.5`.

### Where to implement
- CSS variable overrides → existing theme SCSS blocks in `src/styles/style.scss` (`.light-glass` / `.dark-glass` selectors)
- Orb pseudo-elements → `.first_level_grid_block` or `form.form-entry` scoped to each theme class
- `InputSlot.vue` floating label → add `font-family` and `text-transform` scoped to glass themes via SCSS
- Field gap → `.form_grid_block` or equivalent flex/grid container inside each card

---

## 5. Enum Chips (Select field values)

Enum/select field values are displayed as pill-shaped chips inside field rows. Two variants:

### Neutral chip (no semantic colour)
```css
display: inline-block; padding: 3px 10px; border-radius: 999px;
font-family: 'Space Grotesk', sans-serif; font-size: 11px; font-weight: 600;
/* dark-glass */
background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.7);
border: 1px solid rgba(255,255,255,0.15);
/* light-warm */
background: rgba(255,255,255,0.55); color: #1f1f1f;
border: 1px solid rgba(196,182,163,0.5);
```

### Coloured chips — each enum category has its own colour
Colour is stored as metadata on the enum value in the database. The UI maps it to a CSS class.

| Class | Light bg / ink | Dark bg / ink |
|-------|---------------|---------------|
| `.chip.green`  | `rgba(34,197,94,0.15)` / `#16a34a`  | `rgba(34,197,94,0.18)` / `#4ade80`  |
| `.chip.teal`   | `rgba(20,184,166,0.14)` / `#0f766e` | `rgba(20,184,166,0.18)` / `#2dd4bf` |
| `.chip.blue`   | `rgba(59,130,246,0.14)` / `#2563eb` | `rgba(59,130,246,0.18)` / `#60a5fa` |
| `.chip.indigo` | `rgba(99,102,241,0.14)` / `#4f46e5` | `rgba(99,102,241,0.18)` / `#818cf8` |
| `.chip.purple` | `rgba(168,85,247,0.14)` / `#9333ea` | `rgba(168,85,247,0.18)` / `#c084fc` |
| `.chip.amber`  | `rgba(245,158,11,0.15)` / `#b45309` | `rgba(245,158,11,0.18)` / `#fbbf24` |
| `.chip.orange` | `rgba(249,115,22,0.14)` / `#c2410c` | `rgba(249,115,22,0.18)` / `#fb923c` |
| `.chip.rose`   | `rgba(244,63,94,0.13)` / `#be123c`  | `rgba(244,63,94,0.18)` / `#fb7185`  |
| `.chip.sky`    | `rgba(14,165,233,0.13)` / `#0369a1` | `rgba(14,165,233,0.18)` / `#38bdf8` |
| `.chip.lime`   | `rgba(132,204,22,0.13)` / `#4d7c0f` | `rgba(132,204,22,0.18)` / `#a3e635` |

All chips use `border: 1px solid <bg-color at 0.28–0.35 opacity>` and `border-radius: 999px`.

---

## 6. Out of Scope

- Default (non-glass) themes — no changes
- `light-glass-cool` — removed from scope
- Table views, list views — no changes
- Mobile modal variant — follows same CSS variables, no separate treatment
- New theme switching UI — not in scope
