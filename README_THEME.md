# UI Theming & Reusable Components Guide

This document summarizes the blue theme system and reusable UI building blocks used across the admin/staff mobile app (Flutter).

## 1. AppTheme (lib/styles/app_theme.dart)
Central source of truth for:
- Core palette: `AppTheme.primary`, `darkBlue`, `lightBlue`, semantic colors (`success`, `warning`, `danger`, `info`).
- Gradients: `bgGradient` for page backgrounds, `cardHeaderGradient` (optional decorative usage).
- Shadows: `softShadow`, `mediumShadow` for consistent elevation.
- Typography presets: `heading1`, `heading2`, `body`, `label`, `statNumber`.
- Input decoration helper: `AppTheme.inputDecoration(hint: 'Search...', prefixIcon: Icon(Icons.search))`.
- Card helpers: `cardDecoration`, `elevatedCard()`.
- Button styles: `primaryButtonStyle`, `outlinedButtonStyle`.
- Status color mapping: `AppTheme.statusColor(statusString)` covers complaints + orders statuses.

### Status Mapping Examples
```
PENDING -> warning
NEW / WAITING_PAYMENT -> warning
APPROVED / RESOLVED / COMPLETED / PAID / DELIVERED -> success
CANCELLED / REJECTED -> danger
CONFIRMED / IN_PROGRESS / DELIVERING -> primary
PREPARING / COOKING / READY / WAITING_FOR_SHIPPER -> info
(default) -> textMedium
```
Use with chips or custom UI badges. For complaint status values coming from backend (OPEN, NEED_ADMIN_APPROVAL, etc.) you can still fall back to neutral styling if not mapped.

## 2. Reusable Widgets
| Widget | Purpose |
| ------ | ------- |
| `ThemedScaffold` | Wraps a page with gradient (optional) & consistent background. |
| `StatusChip` | Unified style for status labels; supports `filled` solid variant + icon. |
| `FadeSlideWrapper` | (List) easy staggered fade/slide animation for a collection. |
| `_AnimatedSection` (local) | Lightweight single-section fade/slide used in detail/profile pages. |

### StatusChip Usage
```
StatusChip(
  label: 'ACTIVE',
  color: AppTheme.statusColor('ACTIVE'),
  filled: true, // solid style for dark / gradient backgrounds
  icon: Icons.check,
)
```
Or derive from status string:
```
StatusChip.fromStatus(order.status)
```

## 3. Layout Pattern (Detail Pages)
Pattern applied to Food / Table / User / Profile / Order Detail pages:
1. Gradient header (rounded bottom) containing primary identity (title, avatar/icon, main status chip, key meta).
2. Body uses section cards (`_SectionCard`) with rounded radius 18–22, white surface, soft shadow.
3. Each card groups semantically related data: Info / Payment / Items / Actions.
4. Actions: Place at bottom or inside a final section; use `primaryButtonStyle` or subtle `TextButton`.

## 4. List Page Pattern
- Gradient (via `ThemedScaffold` or `AppTheme.gradientBackground`).
- Top search bar using `AppTheme.inputDecoration`.
- Horizontal filter chips (complaints) or dropdown (orders) -> lighten background with translucency.
- Animated list items: either `FadeSlideWrapper` or local `_Animated*Item` with stagger (delay ~50–70ms * index).
- Expandable card (orders) pattern: preview collapsed, extra meta + subset items + CTA when expanded.

### Example List Item Animation (local widget)
```
class _AnimatedOrderItem extends StatefulWidget { ... }
// Uses AnimationController + FadeTransition + SlideTransition
```

## 5. Adding New Themed Pages (Checklist)
1. Wrap with `ThemedScaffold(appBar: AppBar(...))`.
2. Use gradient header if entity has identity or status.
3. Replace ad‑hoc colored Containers with section card structure.
4. Replace old pill / Container statuses with `StatusChip` (filled on gradient, outline on light surface).
5. Use `AppTheme.inputDecoration` for all search / form inputs.
6. For lists: add stagger animation (either `FadeSlideWrapper` or custom animated item widget).
7. Map any new backend status strings inside `AppTheme.statusColor` (keep neutral fallback).

## 6. Visual Hierarchy Guidelines
- Primary accent = blue gradient or `AppTheme.primary` for interactive focus.
- Success/warning/danger reserved for semantic meaning (avoid using them decoratively).
- Use `filled: true` StatusChip when background is dark / gradient to maintain contrast.
- Shadow selection: `softShadow` for small cards, `mediumShadow` for primary/expanded panels.

## 7. Performance Notes
- Stagger animations: keep duration ≤ 600ms; delay increments ≤ 80ms to avoid sluggish feel.
- Avoid rebuilding heavy FutureBuilders inside list items; fetch list once, derive filtered view in memory.
- When lists become large, consider `ImplicitlyAnimatedList` or pagination; current approach is adequate for moderate volumes.

## 8. Extending Status Mapping
Add new statuses inside `AppTheme.statusColor`. Keep groups semantically clustered (e.g., shipping states share hue family). If a status is purely informational, consider `info` color; if terminal success, use `success`; if reversible in-progress, prefer `primary`.

## 9. Theme Consistency Quick Audit Script (Future Idea)
Potential next step: write a debug-only widget scanning for raw `Container(color: ...)` in admin pages to highlight non-themed usages.

## 10. Migration Legacy → Themed Summary
Legacy pages used plain `Scaffold`, scattered colors, manual status badges. Refactor introduced:
- Central palette & gradients.
- Reusable status chip.
- Section-based detail layout.
- Animated, elevated list cards.
- Consistent search/filter UI.

## 11. Next Possible Enhancements
- Dark mode variant (derive palette shifts on luminance).
- Global spacing scale (e.g., 4/8/12/16/20/24 constants).
- Extract `_SectionCard` into shared widget folder for reuse (currently local in some pages).
- Introduce a `ThemedBottomSheet` helper matching password change sheet style.

## 12. Chatbot Management Theming
The chatbot management module follows the same blue theme principles while introducing conversational UI patterns.

### Structure
- Gradient header + pill TabBar (`Sessions`, `FAQ`, `Knowledge Base`).
- Body surface uses a light neutral background with rounded top corners.
- Each tab content wrapped in `AppTheme.cardDecoration` containers.

### Sessions Tab
- Analytics row uses `_StatBlock` (circular icon accent + stat label + value) reusing `statNumber` + `label` styles.
- Sessions list entries: animated fade+slide (40ms * index) with subtle divider and selection highlight using `AppTheme.ultraLightBlue`.
- Session status badge colors:
  - `active` (default) -> `AppTheme.success`
  - `handed_over` -> `AppTheme.primary`
  - `ended` -> `AppTheme.danger`
  (Consider mapping these into `AppTheme.statusColor` if reused elsewhere.)
- Language rendered via `_LanguageChip` (blue = EN, red = VI) derived from existing semantic colors.

### Conversation View
- Message bubbles differentiate roles:
  - Bot: light blue tint (`lightBlue` with opacity + border).
  - Agent: primary blue tint.
  - Customer: success green tint.
- Each bubble uses consistent padding (12), rounded radius (12), and thin border with semi‑transparent role color.
- Entrance animation: fade + vertical slide (offset 0→.18) with 45ms * index delay.
- Auto‑scroll to bottom after loading a session.
- Optional future enhancements: typing indicator shimmer, streaming token animation, agent reply composer.

### FAQ & Knowledge Base Tabs
- Items transformed into expansion tiles inside themed cards (rounded 16) with invisible dividers.
- Language/tag row uses `_LanguageChip` + inline tag text (ellipsized) to maintain compact vertical rhythm.
- Primary CTA buttons reuse `AppTheme.primaryButtonStyle` for Add actions.

### Reusable Chips
`_LanguageChip(code: 'en')` centralizes language color logic (danger for Vietnamese, primary for English). Future: promote to public widget if needed in other modules.

### Animation Guidelines (Chatbot)
- Keep animation durations ≤ 500ms for snappy feel.
- Delay: 40–45ms per item (sessions vs messages) – shorter vs other pages to reflect real-time chat nature.
- Use combined `FadeTransition` + `SlideTransition` (tween offset Y: .15–.18 to 0) with `Curves.easeOutCubic`.

### Documentation To-Do
- If voucher/request/chatbot statuses are unified later, extend `statusColor` and replace custom mapping.
- Add design rationale for bubble color semantics (bot informational vs. agent actionable vs. customer origin).

---
Chatbot theming aligns with the established system while introducing conversation-specific animation pacing and bubble semantics.

---
Feel free to expand this document as new components mature.
