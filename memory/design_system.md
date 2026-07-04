---
name: design-system
description: QuickBill Studio design system — colors, rules, and redesign scope (July 2026)
metadata:
  type: project
---

## Studio Design System (implemented July 2026)

The entire app was redesigned to use a minimal, modern "Studio" palette. The old green-accent + rainbow-gradient system was fully replaced.

**Why:** User requested a new minimal, modern, trendy color design system. No old colors kept.

### Color Tokens
- Background: `#F7F7F5` (warm white)
- Surface: `#FFFFFF`
- SurfaceElevated: `#F2F2F0`
- Primary: `#0C0C0F` (near-black) — buttons, headers
- Accent: `#5B5FEF` (indigo) — FABs, active states, highlights
- AccentSurface: `#EEEFFC`
- TextPrimary: `#0C0C0F`
- TextSecondary: `#6B6B7A`
- TextTertiary: `#A1A1B0`
- Border: `#E5E5E3`
- Success: `#16A34A` / SuccessSurface: `#DCFCE7`
- Warning: `#D97706` / WarningSurface: `#FEF3C7`
- Error: `#DC2626` / ErrorSurface: `#FEE2E2`
- Info: `#2563EB`

### Design Rules
1. NO rainbow/multi-color gradients
2. AppBar: white background, no elevation, dark text
3. Cards: white + 1px `#E5E5E3` border + borderRadius 16px
4. Primary buttons: `#0C0C0F` background
5. FABs/highlights: `#5B5FEF` indigo accent
6. Stat cards: white + colored left strip (4px) + icon in tinted surface bg
7. Hero/feature cards: solid near-black (`#0C0C0F`) dark card
8. MaterialApp theme is in `main.dart`; design constants in `lib/utils/app_theme.dart`

### Files Updated
- `lib/utils/app_theme.dart` — complete rewrite
- `lib/main.dart` — new MaterialApp theme
- All 19 screens in `lib/screens/` — complete redesign

**How to apply:** When adding new screens or widgets, use `_Studio` color constants class pattern (local to each file) matching the token values above.
