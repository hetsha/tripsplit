# 04 — Design System

This document is the single source of truth for all visual design in TripBook. Every screen, component, and UI element across the web app and Flutter Android app must conform to this system.

The design is an **original implementation** — not a direct copy of any reference application. It follows a **Purple/Indigo premium fintech** direction inspired by the provided reference images.

---

## Design Principles

1. **Premium Fintech Feel**: The app should feel like a high-quality financial tool, not a toy.
2. **Clarity Over Decoration**: Every visual element serves a purpose. No decorative clutter.
3. **Color as Information**: Colors communicate financial status (positive, negative, warning).
4. **Consistent Across Platforms**: Web and Flutter use the same design tokens.
5. **Dark Mode First**: Dark mode is a first-class design target, not an afterthought.
6. **Mobile-First**: Primary design target is 360px–430px mobile screens. Tablet and desktop adapt from there.

---

## 1. Color System

### Primary Palette

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `primary` | `#6C63FF` | 108, 99, 255 | Primary actions, links, active states |
| `primary-dark` | `#4F46E5` | 79, 70, 229 | Primary hover, pressed states |
| `primary-light` | `#818CF8` | 129, 140, 248 | Primary subtle backgrounds |
| `secondary` | `#8B5CF6` | 139, 92, 246 | Secondary actions, accents |
| `accent` | `#D946EF` | 217, 70, 239 | Gradients, highlights |

### Brand Gradients

| Token | Value | Usage |
|-------|-------|-------|
| `brand-gradient` | `linear-gradient(135deg, #6C63FF, #8B5CF6, #D946EF)` | Hero cards, splash, primary CTAs |
| `brand-gradient-subtle` | `linear-gradient(135deg, rgba(108,99,255,0.12), rgba(139,92,246,0.08))` | Card backgrounds, subtle highlights |
| `accent-gradient` | `linear-gradient(135deg, #8B5CF6, #D946EF)` | Secondary gradients |

### Status Colors

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `positive` | `#10B981` | 16, 185, 129 | Profit, income, success, credit balance |
| `positive-light` | `rgba(16,185,129,0.10)` | — | Positive backgrounds |
| `positive-dark` | `#059669` | 5, 150, 105 | Positive hover/pressed |
| `negative` | `#F43F5E` | 244, 63, 94 | Loss, expense, error, debt balance |
| `negative-light` | `rgba(244,63,94,0.10)` | — | Negative backgrounds |
| `negative-dark` | `#E11D48` | 225, 29, 72 | Negative hover/pressed |
| `warning` | `#F59E0B` | 245, 158, 11 | Warnings, due soon, pending |
| `warning-light` | `rgba(245,158,11,0.10)` | — | Warning backgrounds |
| `warning-dark` | `#D97706` | 217, 119, 6 | Warning hover/pressed |
| `info` | `#06B6D4` | 6, 182, 212 | Informational, neutral highlights |
| `info-light` | `rgba(6,182,212,0.10)` | — | Info backgrounds |

### Neutral Palette — Light Mode

| Token | Hex | Usage |
|-------|-----|-------|
| `bg-primary` | `#F8F9FC` | Page background |
| `bg-secondary` | `#F1F3F9` | Section backgrounds |
| `surface` | `#FFFFFF` | Card backgrounds |
| `surface-elevated` | `#FFFFFF` | Elevated cards, modals |
| `border` | `#E2E8F0` | Borders, dividers |
| `border-subtle` | `#F1F5F9` | Subtle dividers |
| `text-primary` | `#18181B` | Headings, primary text |
| `text-secondary` | `#71717A` | Body text, descriptions |
| `text-tertiary` | `#A1A1AA` | Placeholders, hints |
| `text-inverse` | `#FFFFFF` | Text on colored backgrounds |

### Neutral Palette — Dark Mode

| Token | Hex | Usage |
|-------|-----|-------|
| `bg-primary` | `#070A12` | Page background |
| `bg-secondary` | `#0B1020` | Section backgrounds |
| `surface` | `#0F1729` | Card backgrounds |
| `surface-elevated` | `#141C30` | Elevated cards, modals |
| `border` | `rgba(255,255,255,0.08)` | Borders, dividers |
| `border-subtle` | `rgba(255,255,255,0.04)` | Subtle dividers |
| `text-primary` | `#F8FAFC` | Headings, primary text |
| `text-secondary` | `#94A3B8` | Body text, descriptions |
| `text-tertiary` | `#64748B` | Placeholders, hints |
| `text-inverse` | `#070A12` | Text on colored backgrounds |

### Background Effects — Dark Mode

The dark mode background uses subtle radial gradient overlays for depth:

```css
background-image:
  radial-gradient(at 0% 0%, rgba(108,99,255,0.08) 0px, transparent 50%),
  radial-gradient(at 100% 0%, rgba(139,92,246,0.09) 0px, transparent 50%),
  radial-gradient(at 50% 100%, rgba(217,70,239,0.06) 0px, transparent 50%);
background-attachment: fixed;
```

---

## 2. Typography

### Font Family

| Platform | Font Stack |
|----------|-----------|
| Web | `'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif` |
| Flutter | `'Plus Jakarta Sans'` (bundled) or system font fallback |

### Type Scale

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `display-lg` | 36px | 800 | 1.1 | -0.02em | Hero numbers, large financial figures |
| `display` | 28px | 700 | 1.2 | -0.01em | Screen titles, section headers |
| `heading-lg` | 22px | 700 | 1.3 | -0.01em | Card titles |
| `heading` | 18px | 600 | 1.35 | 0 | Subsection headers |
| `heading-sm` | 16px | 600 | 1.4 | 0 | Small headers, list group headers |
| `body-lg` | 16px | 400 | 1.5 | 0 | Primary body text |
| `body` | 14px | 400 | 1.5 | 0 | Secondary body text, descriptions |
| `body-sm` | 13px | 400 | 1.45 | 0 | Captions, helper text |
| `label-lg` | 14px | 600 | 1.4 | 0.01em | Button text, tab labels |
| `label` | 13px | 600 | 1.3 | 0.01em | Chip labels, badge text |
| `label-sm` | 11px | 600 | 1.2 | 0.02em | Small badges, superscripts |
| `mono` | 13px | 500 | 1.4 | 0 | Amounts, codes, transaction IDs |

### Financial Number Formatting

- Amounts use `mono` font weight for alignment.
- Currency symbol is slightly smaller than the number: `₹` at 0.85em, number at 1em.
- Thousands separators: `₹1,23,456` (Indian numbering).
- Decimals: Always 2 digits for display (`₹1,200.00`), omit `.00` in casual contexts.

---

## 3. Spacing Scale

All spacing uses a 4px base unit. Values are multiples of 4.

| Token | Value | Usage |
|-------|-------|-------|
| `space-0` | 0px | — |
| `space-1` | 4px | Tight inner padding (icon gaps) |
| `space-2` | 8px | Small gaps (chip padding, inline spacing) |
| `space-3` | 12px | Card inner padding (compact) |
| `space-4` | 16px | Standard card padding, section gaps |
| `space-5` | 20px | Card padding (default) |
| `space-6` | 24px | Section spacing, form field gaps |
| `space-8` | 32px | Major section spacing |
| `space-10` | 40px | Page-level vertical spacing |
| `space-12` | 48px | Large section breaks |
| `space-16` | 64px | Screen-level vertical padding |

### Page-Level Spacing

- **Horizontal page padding**: `space-5` (20px) on mobile, `space-8` (32px) on tablet/desktop.
- **Vertical page padding**: `space-5` (20px) top and bottom.
- **Section gap**: `space-6` (24px) between major sections.
- **Card gap**: `space-4` (16px) between cards in a list.

---

## 4. Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 10px | Chips, small buttons, tags |
| `radius-md` | 16px | Cards, inputs, modals |
| `radius-lg` | 24px | Large cards, bottom sheets, hero sections |
| `radius-xl` | 32px | Feature cards, prominent containers |
| `radius-full` | 9999px | Avatars, pill buttons, badges |

---

## 5. Shadows

### Light Mode

| Token | Value |
|-------|-------|
| `shadow-sm` | `0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)` |
| `shadow-md` | `0 4px 12px rgba(0,0,0,0.06), 0 2px 4px rgba(0,0,0,0.04)` |
| `shadow-lg` | `0 10px 30px rgba(0,0,0,0.08), 0 4px 8px rgba(0,0,0,0.04)` |
| `shadow-sheet` | `0 -4px 20px rgba(0,0,0,0.08)` |

### Dark Mode

| Token | Value |
|-------|-------|
| `shadow-sm` | `0 1px 2px rgba(0,0,0,0.3)` |
| `shadow-md` | `0 4px 20px -2px rgba(0,0,0,0.5), 0 2px 6px -2px rgba(0,0,0,0.3)` |
| `shadow-lg` | `0 10px 30px -4px rgba(0,0,0,0.7), 0 4px 10px -4px rgba(0,0,0,0.4)` |
| `shadow-sheet` | `0 -10px 40px -5px rgba(0,0,0,0.6)` |

### Glassmorphism (Dark Mode Cards)

```css
background: rgba(15, 23, 42, 0.55);
backdrop-filter: blur(24px);
-webkit-backdrop-filter: blur(24px);
border: 1px solid rgba(255, 255, 255, 0.08);
```

---

## 6. Component Specifications

### 6.1 Cards

**Default Card**
```
Background:    surface (light) / glassmorphism (dark)
Border:        1px solid border
Border Radius: radius-md (16px)
Padding:       space-5 (20px)
Shadow:        shadow-sm
```

**Elevated Card** (prominent, e.g., balance card, hero)
```
Background:    brand-gradient (dark mode) / surface (light mode)
Border Radius: radius-lg (24px)
Padding:       space-6 (24px)
Shadow:        shadow-md
```

**Compact Card** (list items, transaction rows)
```
Background:    surface
Border Radius: radius-md (16px)
Padding:       space-3 (12px) vertical, space-4 (16px) horizontal
Shadow:        none
```

### 6.2 Buttons

**Primary Button**
```
Background:    primary (#6C63FF)
Text Color:    #FFFFFF
Font:          label-lg (14px/600)
Height:        52px
Border Radius: radius-md (16px)
Padding:       0 space-6 (24px)
Shadow:        0 4px 12px rgba(108,99,255,0.3)
Hover:         primary-dark (#4F46E5)
Active:        scale(0.98)
```

**Secondary Button**
```
Background:    transparent
Border:        1.5px solid border
Text Color:    text-primary
Font:          label-lg (14px/600)
Height:        52px
Border Radius: radius-md (16px)
Padding:       0 space-6 (24px)
Hover:         bg-secondary
```

**Ghost Button**
```
Background:    transparent
Text Color:    primary
Font:          label-lg (14px/600)
Height:        44px
Border Radius: radius-sm (10px)
Padding:       0 space-4 (16px)
Hover:         primary-light background
```

**Danger Button**
```
Background:    negative (#F43F5E)
Text Color:    #FFFFFF
Font:          label-lg (14px/600)
Height:        52px
Border Radius: radius-md (16px)
Shadow:        0 4px 12px rgba(244,63,94,0.3)
```

**Icon Button** (FAB, action buttons)
```
Size:          52px × 52px
Background:    primary / brand-gradient
Icon Color:    #FFFFFF
Icon Size:     24px
Border Radius: radius-full (9999px)
Shadow:        shadow-md
```

**Disabled State** (all button types)
```
Opacity:       0.5
Pointer:       not-allowed
Shadow:        none
```

### 6.3 Inputs

**Text Input**
```
Height:        52px
Background:    bg-secondary (light) / surface (dark)
Border:        1.5px solid border
Border Radius: radius-md (16px)
Padding:       0 space-5 (16px)
Font:          body-lg (16px/400)
Text Color:    text-primary
Placeholder:   text-tertiary
Focus:         border-color → primary, box-shadow → 0 0 0 3px rgba(108,99,255,0.15)
Error:         border-color → negative, helper text → negative
```

**Amount Input** (specialized for financial entries)
```
Height:        60px
Background:    bg-secondary
Border:        2px solid border
Border Radius: radius-md (16px)
Padding:       0 space-6 (24px)
Font:          display (28px/700), mono
Text Color:    text-primary
Currency:      ₹ prefix, slightly smaller (0.85em)
Focus:         border-color → primary
```

**Search Input**
```
Height:        44px
Background:    bg-secondary
Border:        1px solid border
Border Radius: radius-full (9999px)
Padding:       0 space-5 (16px) left, space-10 (40px) right for icon
Icon:          search (16px), text-tertiary
```

### 6.4 Chips / Tags

**Filter Chip**
```
Height:        36px
Background:    bg-secondary
Border:        1px solid border
Border Radius: radius-sm (10px)
Padding:       0 space-3 (12px)
Font:          label (13px/600)
Text Color:    text-secondary
Active:        background → primary-light, border → primary, text → primary
```

**Category Chip**
```
Height:        32px
Background:    category color at 10% opacity
Border Radius: radius-full (9999px)
Padding:       0 space-3 (12px)
Font:          label-sm (11px/600)
Text Color:    category color
Icon:          category icon (14px), same color
```

### 6.5 Badges

**Status Badge**
```
Height:        24px
Background:    status color at 10% opacity
Border Radius: radius-full (9999px)
Padding:       0 space-2 (8px)
Font:          label-sm (11px/600)
Text Color:    status color
```

**Count Badge** (notification dot)
```
Min Width:     20px
Height:        20px
Background:    negative
Border Radius: radius-full (9999px)
Padding:       0 space-1 (4px)
Font:          label-sm (11px/700)
Text Color:    #FFFFFF
Position:      Top-right of parent
```

### 6.6 Avatars

**Circle Avatar**
```
Sizes:         32px (sm), 40px (md), 48px (lg), 64px (xl)
Border Radius: radius-full (9999px)
Background:    user's avatar_color
Text Color:    #FFFFFF
Font:          label-lg (14px/600) for initials
Border:        2px solid surface (dark) / white (light)
```

**Avatar Stack** (group members)
```
Layout:        Horizontal, overlapping by -8px
Max Visible:   3 avatars
Overflow:      "+N" badge for remaining
Badge:         background → primary, text → #FFFFFF
```

### 6.7 Bottom Navigation

```
Height:        72px
Background:    surface (dark mode: glassmorphism)
Border Top:    1px solid border
Shadow:        shadow-sheet
Items:         5 (Home, Transactions, People, Settle, More)
Item Width:    Equal distribution
Icon Size:     24px
Label Font:    label-sm (11px/600)
Active:        icon → primary, label → primary
Inactive:      icon → text-tertiary, label → text-tertiary
FAB Position:  Center-top, overlapping by -28px
```

### 6.8 Bottom Sheet

```
Background:    surface
Border Radius: radius-lg (24px) top-left, radius-lg top-right
Shadow:        shadow-sheet
Max Height:    90vh
Handle:        32px × 4px, radius-full, bg → border, centered, margin-top space-3
Padding:       space-5 (20px) top (below handle), space-6 (24px) sides
Animation:     Slide up, 300ms ease-out
Backdrop:      rgba(0,0,0,0.4), fade in
```

### 6.9 Modal / Dialog

```
Background:    surface
Border Radius: radius-lg (24px)
Shadow:        shadow-lg
Max Width:     400px (mobile: full width minus 32px)
Padding:       space-6 (24px)
Title Font:    heading-lg (22px/700)
Body Font:     body-lg (16px/400)
Actions:       Row of buttons, primary right, secondary/ghost left
Animation:     Scale from 0.95 + fade, 200ms ease-out
Backdrop:      rgba(0,0,0,0.5), fade in
```

### 6.10 Empty State

```
Layout:        Centered vertical
Icon:          64px, text-tertiary color, opacity 0.5
Title:         heading (18px/600), text-secondary
Description:   body (14px/400), text-tertiary, max-width 280px
Action:        Primary button (if applicable)
Padding:       space-10 (40px) vertical
```

### 6.11 Loading State

**Skeleton Loader**
```
Background:    bg-secondary
Border Radius: radius-sm (10px)
Animation:     Shimmer gradient (left to right, 1.5s infinite)
Gradient:      linear-gradient(90deg, bg-secondary 25%, border 50%, bg-secondary 75%)
```

**Spinner**
```
Size:          32px (default), 24px (inline), 48px (full-page)
Color:         primary
Type:          Circular, 3px stroke, round linecap
```

**Full-Page Loading**
```
Layout:        Centered vertically and horizontally
Spinner:       48px
Text:          body (14px), text-tertiary, below spinner
```

### 6.12 Error State

```
Layout:        Centered vertical (same as empty state)
Icon:          Alert triangle or X circle, 64px, negative color
Title:         heading (18px/600), text-primary
Description:   body (14px/400), text-secondary, max-width 280px
Action:        Secondary button "Try Again"
```

### 6.13 Success State

**Inline Success** (after action)
```
Background:    positive-light
Border:        1px solid positive
Border Radius: radius-md (16px)
Padding:       space-3 (12px) vertical, space-4 (16px) horizontal
Icon:          Check circle, 20px, positive
Text:          body (14px), positive-dark
```

**Full Success** (e.g., settlement confirmed)
```
Layout:        Centered vertical
Icon:          Check circle, 80px, positive
Title:         heading-lg (22px/700), text-primary
Description:   body (14px), text-secondary
Action:        Primary button "Done"
Animation:     Icon scale-in with bounce, 400ms
```

---

## 7. Charts

### Chart Color Palette

| Index | Color | Usage |
|-------|-------|-------|
| 1 | `#6C63FF` | Primary data series |
| 2 | `#8B5CF6` | Secondary data series |
| 3 | `#D946EF` | Tertiary data series |
| 4 | `#10B981` | Positive/income |
| 5 | `#F43F5E` | Negative/expense |
| 6 | `#F59E0B` | Warning/pending |
| 7 | `#06B6D4` | Info/neutral |
| 8 | `#EC4899` | Accent |

### Donut Chart (Category Breakdown)

```
Stroke Width:    24px (mobile), 32px (tablet/desktop)
Stroke Linecap:  Round
Gap:             2px between segments
Center Text:     Total amount (display-lg font)
Animation:       Segment reveal, 600ms ease-out
Legend:          Below chart, horizontal chips with color dot + label + amount
```

### Bar Chart (Monthly Comparison)

```
Bar Width:       24px
Bar Radius:      8px (top only)
Bar Gap:         8px
Grid Lines:      border-subtle, dashed
Labels:          body-sm, text-tertiary
Values:          On bar top or inside bar, label-sm
Animation:       Grow from bottom, 400ms ease-out per bar
```

### Line Chart (Spending Trend)

```
Line Width:      2.5px
Point Radius:    4px (default), 6px (on hover)
Point Fill:      surface
Point Stroke:    primary (2px)
Fill Area:       primary at 10% opacity
Grid Lines:      border-subtle, dashed
Animation:       Draw from left to right, 600ms ease-out
```

---

## 8. Navigation Structure

### Web — Bottom Navigation (Mobile)

```
┌─────────────────────────────────────────┐
│                                         │
│              [Page Content]             │
│                                         │
├─────────────────────────────────────────┤
│  Home  │  History  │  [FAB]  │ People │ More │
│                                         │
└─────────────────────────────────────────┘
```

- 5 tabs: Home, Transactions, People, Settle, More
- FAB (Floating Action Button) centered above navigation
- Active tab: primary color icon + label
- Inactive tab: text-tertiary icon + label

### Flutter — Bottom Navigation

Same structure as web. See `24-FLUTTER-ARCHITECTURE.md` for implementation details.

### Web — Desktop Sidebar (Future)

For viewport widths ≥1024px, the bottom navigation converts to a left sidebar:

```
┌──────┬──────────────────────────────────┐
│      │                                  │
│ Logo │         [Page Content]           │
│      │                                  │
│ Home │                                  │
│ Trans│                                  │
│ People│                                 │
│ Settle│                                 │
│ More │                                  │
│      │                                  │
└──────┴──────────────────────────────────┘
```

---

## 9. Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile S | 320px | Single column, compact spacing |
| Mobile M | 375px | Single column, standard spacing |
| Mobile L | 430px | Single column, standard spacing |
| Tablet | 768px | Single column, max-width 540px centered |
| Desktop | 1024px | Sidebar + content, max-width 960px content |
| Desktop L | 1280px | Sidebar + content, max-width 1120px content |

### Responsive Rules

- **Page padding**: `space-5` (20px) mobile → `space-8` (32px) tablet+.
- **Card padding**: `space-5` (20px) all sizes.
- **Card grid**: 1 column mobile → 2 columns tablet → 3 columns desktop (for card grids like analytics).
- **Bottom nav**: Visible mobile/tablet → hidden on desktop (replaced by sidebar).
- **Max content width**: 540px mobile → 960px tablet → 1120px desktop.
- **Hero card**: Full width mobile → 60% width on desktop.
- **Charts**: Full width all sizes, with min-height 200px.

---

## 10. Transitions and Animations

| Token | Duration | Easing | Usage |
|-------|----------|--------|-------|
| `transition-fast` | 150ms | ease | Button hover, chip toggle |
| `transition-normal` | 250ms | cubic-bezier(0.4, 0, 0.2, 1) | Card hover, modal open |
| `transition-bounce` | 350ms | cubic-bezier(0.175, 0.885, 0.32, 1.275) | FAB press, success check |
| `transition-slide` | 300ms | ease-out | Bottom sheet open/close |

### Page Transitions

- **Forward navigation**: Slide left, 250ms.
- **Back navigation**: Slide right, 250ms.
- **Modal/Bottom sheet**: Fade backdrop + slide up content.

---

## 11. Iconography

### Icon Library

- **Web**: Lucide Icons (SVG, inline or sprite)
- **Flutter**: `lucide_icons` package (matching web)

### Icon Sizes

| Context | Size |
|---------|------|
| Navigation icon | 24px |
| Button icon | 20px |
| Card/section icon | 20px |
| Inline icon | 16px |
| Badge icon | 12px |
| Avatar fallback | 28px (initials) |

### Icon Colors

- Default: Inherit from text color.
- Status: Use status color (positive, negative, warning).
- Primary action: primary color.
- Disabled: text-tertiary.

---

## 12. Platform-Specific Adaptations

### Web

- CSS custom properties for all tokens (defined in `:root` and `[data-theme="dark"]`).
- Glassmorphism via `backdrop-filter`.
- Service Worker for offline static caching.
- Touch targets minimum 44px × 44px.

### Flutter

- All design tokens defined in `AppColors` and `AppTheme` classes.
- Glassmorphism via `BackdropFilter` widget.
- `GlassCard` widget for consistent card rendering.
- `MaterialApp` with `ThemeData` for light/dark modes.
- See `24-FLUTTER-ARCHITECTURE.md` for implementation mapping.

---

## 13. Accessibility

- **Color contrast**: Minimum 4.5:1 for body text, 3:1 for large text.
- **Touch targets**: Minimum 44px × 44px for all interactive elements.
- **Screen reader labels**: All interactive elements must have semantic labels.
- **Focus indicators**: Visible focus ring (2px primary outline) for keyboard navigation.
- **Error messages**: Linked to inputs via `aria-describedby`.
- **Financial amounts**: Always accompanied by text labels (not color alone).

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we support multi-language UI beyond English/Hindi? | i18n scope, design tokens for RTL |
| OQ-2 | Is haptic feedback required for Flutter actions? | Flutter implementation |
| OQ-3 | Should charts support pinch-to-zoom on mobile? | Chart library configuration |
| OQ-4 | What is the maximum number of categories to display before collapsing? | Category list UX |

---

## Dependencies

- `00-PROJECT-OVERVIEW.md` — Product vision and locked decisions
- `03-SCREEN-SPECIFICATION.md` — Screen inventory (uses these components)

## Related Documents

- `03-SCREEN-SPECIFICATION.md` — Every screen using these components
- `23-FRONTEND-ARCHITECTURE.md` — Web implementation of these tokens
- `24-FLUTTER-ARCHITECTURE.md` — Flutter implementation of these tokens
