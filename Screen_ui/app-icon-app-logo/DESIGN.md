---
name: My Khata
colors:
  surface: '#faf9f9'
  surface-dim: '#dbdada'
  surface-bright: '#faf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f3'
  surface-container: '#efeded'
  surface-container-high: '#e9e8e8'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#40484a'
  inverse-surface: '#2f3031'
  inverse-on-surface: '#f2f0f0'
  outline: '#71787a'
  outline-variant: '#c0c8ca'
  surface-tint: '#38656d'
  primary: '#13434b'
  on-primary: '#ffffff'
  primary-container: '#2e5b63'
  on-primary-container: '#a3d1da'
  inverse-primary: '#a1ced7'
  secondary: '#575d79'
  on-secondary: '#ffffff'
  secondary-container: '#d9deff'
  on-secondary-container: '#5b617d'
  tertiary: '#58323f'
  on-tertiary: '#ffffff'
  tertiary-container: '#724856'
  on-tertiary-container: '#f1baca'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bceaf4'
  primary-fixed-dim: '#a1ced7'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#1e4d55'
  secondary-fixed: '#dce1ff'
  secondary-fixed-dim: '#bfc5e5'
  on-secondary-fixed: '#141a32'
  on-secondary-fixed-variant: '#3f4660'
  tertiary-fixed: '#ffd9e3'
  tertiary-fixed-dim: '#eeb8c8'
  on-tertiary-fixed: '#31111d'
  on-tertiary-fixed-variant: '#633b48'
  background: '#faf9f9'
  on-background: '#1b1c1c'
  surface-variant: '#e3e2e2'
typography:
  display-lg:
    fontFamily: Noto Sans
    fontSize: 57px
    fontWeight: '400'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Noto Sans
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
  headline-sm:
    fontFamily: Noto Sans
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
  title-lg:
    fontFamily: Noto Sans
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Noto Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0.15px
  body-lg:
    fontFamily: Noto Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Noto Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Noto Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: Noto Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Noto Sans
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  margin-mobile: 16px
  margin-desktop: 24px
  gutter: 16px
  component-gap: 12px
  stack-space: 8px
---

## Brand & Style
The design system is built on the principles of **Modern Material (Material You)**, focusing on accessibility, clarity, and personal reliability. As a digital ledger, the interface must feel as lightweight as a paper notebook but as powerful as a modern fintech application. 

The aesthetic is **Clean and Minimal**, utilizing the M3 design language's emphasis on color-coded surfaces and expressive motion. It prioritizes the "Personal" in personal finance, avoiding overly corporate stiffness in favor of a friendly, approachable, and trustworthy user experience. The interface relies on generous whitespace and a clear structural hierarchy to make complex financial tallies feel manageable at a glance.

## Colors
The color system utilizes a **Deep Teal** seed to derive a balanced Material You palette. This provides a professional yet "personal ledger" feel, distinct from aggressive banking blues.

- **Primary (Deep Teal):** Used for key actions, active states, and brand identity.
- **Positive (Green):** Specifically used for "You are owed" or "Inflow" balances.
- **Negative (Red):** Reserved for "You owe" or "Outflow" balances.
- **Settled (Gray):** Used for neutralized or zeroed-out transactions.
- **Surface & Containers:** The design system uses tonal palettes for surfaces. In light mode, surfaces are tinted with the primary color at very low intensities (98-95 luminance); in dark mode, surfaces adopt deep charcoal tones with primary overlays.

## Typography
This design system uses **Noto Sans** for its universal legibility and neutral, friendly character. The type scale follows the Material 3 specification, ensuring a clear hierarchy between transaction amounts and metadata.

- **Display & Headline:** Used for large balance displays and screen titles. The `display-lg` role is specifically for the primary wallet or ledger total.
- **Title:** Used for person names in the contact list and section headers.
- **Body:** Used for transaction notes and general descriptions.
- **Label:** Used for timestamps, status chips, and button text.

## Layout & Spacing
The layout follows a **Fluid Grid** model with a base unit of **4px**. 

- **Mobile:** 4-column grid with 16px side margins and 16px gutters.
- **Tablet/Desktop:** 12-column grid with 24px margins. Content is typically centered in a maximum-width container of 840px to maintain readability for ledger rows.
- **Vertical Rhythm:** Transaction rows use a fixed height of 72px (three-line) or 56px (two-line) to maintain a consistent scanning rhythm.
- **Safe Areas:** Modal bottom sheets include a 24px bottom padding to account for OS-level navigation bars.

## Elevation & Depth
In accordance with Material 3, depth is primarily communicated through **Tonal Layering** rather than heavy shadows.

- **Level 0 (Surface):** The base background of the app.
- **Level 1 (Cards/Lists):** A subtle tint overlay. Used for individual transaction items in a feed.
- **Level 2 (Search Bars/Chips):** Used for interactive elements that sit above the surface.
- **Level 3 (Modals/Bottom Sheets):** Clear separation for the "Add Entry" flow.
- **Shadows:** When used, shadows are extremely soft and diffused (Level 3: 0px 8px 12px rgba(0,0,0,0.08)). Outlines are preferred over shadows for high-contrast accessibility on containers.

## Shapes
The shape language is friendly and modern. A **16px (1rem)** corner radius is the standard for most containers.

- **Small Components:** Buttons and input fields use a 16px radius.
- **Medium Components:** Cards and list containers use a 16px or 24px (rounded-lg) radius.
- **Large Components:** Modal bottom sheets use a 28px (rounded-xl) top corner radius to create a soft, inviting container for data entry.
- **Navigation:** Floating Action Buttons (FABs) utilize a 16px rounded-square shape.

## Components
- **Balance Cards:** Large containers at the top of the screen. Use `headline-lg` for the amount. The container background should subtly shift to `positive_color` or `negative_color` (at 10% opacity) based on the net balance.
- **Transaction Rows:** 
    - Left: Avatar (Circle) with initials.
    - Center: Name (Title-md) and Date/Note (Body-md).
    - Right: Amount (Title-md) colored according to the green/red/gray status.
- **Buttons:** Filled buttons for primary actions (e.g., "Add Entry"). Text is all-caps or title case based on the `label-lg` style.
- **Modal Bottom Sheets:** The primary method for adding or editing transactions. They should slide from the bottom, covering 50-90% of the screen, with a centered drag handle at the top.
- **Input Fields:** Outlined variants with 16px corner radius. Floating labels are used to maintain context in dense financial forms.
- **Chips:** Used for filtering "Settled," "Due," or "Overdue" transactions. Pill-shaped with a 1px stroke.