# Design Style Guide

## Coop Crossword - Comprehensive Design System

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color Palette](#color-palette)
3. [Typography](#typography)
4. [Spacing System](#spacing-system)
5. [Shadows & Elevation](#shadows--elevation)
6. [Border Radius](#border-radius)
7. [Components](#components)
8. [Interactive States](#interactive-states)
9. [Layout Principles](#layout-principles)
10. [Animation & Transitions](#animation--transitions)
11. [Responsive Design](#responsive-design)

---

## Design Philosophy

The Coop Crossword design system is built on principles of **clarity, simplicity, and accessibility**. The interface prioritizes:

- **Minimalism**: Clean, uncluttered layouts with purposeful use of white space
- **Consistency**: Unified patterns and components across all pages
- **Accessibility**: High contrast ratios, readable fonts, and clear interactive states
- **Playfulness**: Subtle use of color and animation to enhance the crossword-solving experience
- **Responsiveness**: Seamless experience across desktop, tablet, and mobile devices

---

## Color Palette

### Primary Colors

```css
--primary-color: #2563eb; /* Blue 600 - Main brand color */
--primary-hover: #1d4ed8; /* Blue 700 - Hover states */
```

**Usage**: Primary actions, links, headers, active states, and key interactive elements.

### Accent Colors

```css
--accent-teal: #14b8a6; /* Teal 500 - Tags, highlights, volume sliders */
--accent-yellow: #fbbf24; /* Amber 400 - Toggle switches (on), warnings */
--accent-purple: #a78bfa; /* Violet 400 - Level cards, decorative elements */
--accent-pink: #f472b6; /* Pink 400 - Progress indicators, highlights */
--accent-light-blue: #60a5fa; /* Blue 400 - Cell highlights, selections */
```

**Usage**:

- **Teal**: Upgrade tags, volume sliders, progress indicators
- **Yellow**: Active toggle switches, countdown buttons, highlights
- **Purple**: Difficult level cards, decorative accents
- **Pink**: Progress highlights in grids, special indicators
- **Light Blue**: Selected cells, active selections

### Neutral Colors

```css
--background-color: #f8fafc; /* Slate 50 - Page background */
--surface-color: #ffffff; /* White - Cards, panels, surfaces */
--text-primary: #0f172a; /* Slate 900 - Primary text */
--text-secondary: #64748b; /* Slate 500 - Secondary text */
--border-color: #e2e8f0; /* Slate 200 - Borders, dividers */
--secondary-color: #64748b; /* Slate 500 - Secondary elements */
```

**Usage**:

- **Background**: Main page background
- **Surface**: Cards, panels, modals, input fields
- **Text Primary**: Headings, body text, important labels
- **Text Secondary**: Helper text, captions, metadata
- **Border**: Dividers, card borders, input borders

### Level Card Colors

```css
--level-easy-bg: #ffffff; /* White - Easy level cards */
--level-normal-bg: #fef3c7; /* Amber 100 - Normal level cards */
--level-difficult-bg: #f3e8ff; /* Violet 100 - Difficult level cards */
```

**Usage**: Background colors for level selection cards to provide visual hierarchy and differentiation.

### State Colors

```css
--success-color: #10b981; /* Green 500 - Success states */
--error-color: #ef4444; /* Red 500 - Error states */
--warning-color: #f59e0b; /* Amber 500 - Warning states */
--info-color: #3b82f6; /* Blue 500 - Informational states */
```

**Usage**: Feedback messages, validation states, alerts.

### Crossword-Specific Colors

```css
--cell-selected-bg: #eff6ff; /* Blue 50 - Selected cell background */
--cell-highlighted-bg: #fef3c7; /* Amber 100 - Highlighted cell background */
--clue-selected-bg: #fef3c7; /* Amber 100 - Selected clue background */
--clue-selected-border: #f59e0b; /* Amber 500 - Selected clue border */
```

**Usage**: Crossword grid interactions, clue highlighting, selection states.

---

## Typography

### Font Family

```css
font-family:
  -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Oxygen", "Ubuntu",
  "Cantarell", sans-serif;
```

**System font stack** ensures native feel across platforms and optimal performance.

### Font Size Scale

#### Standard Font Sizes (for regular pages)

```css
--font-xs: 0.75rem; /* 12px - Labels, captions */
--font-sm: 0.875rem; /* 14px - Small text, metadata */
--font-base: 1rem; /* 16px - Body text (default) */
--font-lg: 1.125rem; /* 18px - Emphasized text */
--font-xl: 1.25rem; /* 20px - Subheadings */
--font-2xl: 1.5rem; /* 24px - Section headings */
--font-3xl: 1.875rem; /* 30px - Page subheadings */
--font-4xl: 2.25rem; /* 36px - Large headings */
--font-5xl: 3rem; /* 48px - Hero titles */
```

#### Crossword-Specific Font Sizes (relative units for responsive scaling)

```css
--crossword-font-xs: 0.5em;
--crossword-font-sm: 0.75em;
--crossword-font-base: 1em;
--crossword-font-lg: 1.25em;
--crossword-font-xl: 1.5em;
--crossword-font-2xl: 2em;
--crossword-font-3xl: 2.5em;
--crossword-font-4xl: 3em;
--crossword-font-5xl: 3.5em;
--crossword-font-6xl: 4em;
```

**Usage**: Crossword interface uses relative units (`em`) to scale proportionally with the grid size.

### Font Weights

- **400 (Regular)**: Body text, default weight
- **500 (Medium)**: Links, interactive elements
- **600 (Semibold)**: Headings, labels, emphasis
- **700 (Bold)**: Hero titles, strong emphasis

### Line Height

```css
line-height: 1.6; /* Default for body text */
```

**Usage**:

- Body text: `1.6`
- Headings: `1.2` - `1.4`
- Tight spacing: `1.2`

### Letter Spacing

```css
letter-spacing: -0.025em; /* For large headings */
```

**Usage**: Negative letter spacing for large headings (48px+) to improve readability.

---

## Spacing System

The spacing system uses a consistent scale based on `rem` units:

```css
--spacing-xs: 0.25rem; /* 4px - Tight spacing, icon padding */
--spacing-sm: 0.5rem; /* 8px - Small gaps, compact layouts */
--spacing-md: 1rem; /* 16px - Default spacing, standard gaps */
--spacing-lg: 1.5rem; /* 24px - Section spacing, larger gaps */
--spacing-xl: 2rem; /* 32px - Major sections, card padding */
--spacing-2xl: 3rem; /* 48px - Page-level spacing, hero sections */
```

### Usage Guidelines

- **XS**: Icon padding, tight list items
- **SM**: Button padding, small gaps between related elements
- **MD**: Default spacing between elements, standard padding
- **LG**: Section dividers, card internal spacing
- **XL**: Card padding, major section spacing
- **2XL**: Page margins, hero section spacing

### Spacing in Components

- **Cards**: `padding: var(--spacing-lg)` or `var(--spacing-xl)`
- **Buttons**: `padding: var(--spacing-sm) var(--spacing-md)`
- **Inputs**: `padding: var(--spacing-sm)`
- **Grid gaps**: `gap: var(--spacing-lg)` or `var(--spacing-xl)`

---

## Shadows & Elevation

Shadows provide visual hierarchy and depth:

```css
--shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
```

### Usage

- **SM**: Subtle elevation, default cards, inputs
- **MD**: Hover states, elevated cards, buttons on hover
- **LG**: Modals, dropdowns, floating elements

### Elevation Hierarchy

1. **Level 0**: No shadow (background, text)
2. **Level 1**: `shadow-sm` (cards, inputs)
3. **Level 2**: `shadow-md` (hovered cards, active buttons)
4. **Level 3**: `shadow-lg` (modals, tooltips)

---

## Border Radius

Rounded corners create a modern, friendly aesthetic:

```css
--radius-sm: 0.375rem; /* 6px - Small elements, tags */
--radius-md: 0.5rem; /* 8px - Buttons, inputs, cards */
--radius-lg: 0.75rem; /* 12px - Large cards, panels */
```

### Usage

- **SM**: Tags, badges, small buttons
- **MD**: Standard buttons, inputs, default cards
- **LG**: Large cards, panels, modals

---

## Components

### Buttons

#### Primary Button

```css
.button-primary {
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: var(--radius-md);
  padding: var(--spacing-sm) var(--spacing-md);
  font-size: var(--font-base);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.button-primary:hover {
  background-color: var(--primary-hover);
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}
```

#### Secondary Button

```css
.button-secondary {
  background-color: var(--surface-color);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: var(--spacing-sm) var(--spacing-md);
  font-size: var(--font-base);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.button-secondary:hover {
  background-color: var(--background-color);
  border-color: var(--primary-color);
  color: var(--primary-color);
}
```

#### Countdown Button

Buttons with a countdown mechanism (3 seconds) that require confirmation:

- **Initial state**: Primary color background
- **Clicked state**: Gradient animation from clicked color to initial color
- **Animation**: 3-second linear animation with `slideInFromRight` keyframe

### Cards

#### Standard Card

```css
.card {
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: var(--spacing-lg);
  box-shadow: var(--shadow-sm);
  transition: all 0.2s ease-in-out;
}

.card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}
```

#### Level Card Variants

- **Easy**: White background (`--level-easy-bg`)
- **Normal**: Light yellow background (`--level-normal-bg`)
- **Difficult**: Light purple background (`--level-difficult-bg`)

All level cards include:

- Grid preview (5x5) showing puzzle pattern
- Level name and description
- Count badge (rounded rectangle)
- Optional "Upgraded" tag (teal, top-right corner)

### Toggle Switches

```css
.toggle {
  width: 44px;
  height: 24px;
  background-color: var(--border-color);
  border-radius: 12px;
  position: relative;
  cursor: pointer;
  transition: background-color 0.2s ease-in-out;
}

.toggle.active {
  background-color: var(--accent-yellow);
}

.toggle::after {
  content: "";
  position: absolute;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background-color: white;
  top: 2px;
  left: 2px;
  transition: transform 0.2s ease-in-out;
  box-shadow: var(--shadow-sm);
}

.toggle.active::after {
  transform: translateX(20px);
}
```

**States**:

- **Off**: Grey background, toggle on left
- **On**: Yellow background (`--accent-yellow`), toggle on right

### Sliders

#### Volume Slider

```css
.slider {
  width: 100%;
  height: 6px;
  border-radius: 3px;
  background-color: var(--border-color);
  outline: none;
  -webkit-appearance: none;
}

.slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background-color: var(--accent-teal);
  cursor: pointer;
  box-shadow: var(--shadow-sm);
}

.slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background-color: var(--accent-teal);
  cursor: pointer;
  border: none;
  box-shadow: var(--shadow-sm);
}
```

**Features**:

- Teal thumb color (`--accent-teal`)
- Speaker icons on both ends (muted/full volume)
- Smooth interaction

### Input Fields

```css
.input {
  width: 100%;
  padding: var(--spacing-sm);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-sm);
  font-size: var(--font-base);
  background-color: var(--background-color);
  color: var(--text-primary);
  transition: border-color 0.2s ease-in-out;
}

.input:focus {
  outline: none;
  border-color: var(--primary-color);
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}
```

### Crossword Grid

#### Grid Container

```css
#grid {
  border-left: 1px solid var(--text-primary);
  border-top: 1px solid var(--text-primary);
  background-color: var(--text-primary);
  font-size: var(--crossword-font-4xl);
}
```

#### Cells

```css
.cell {
  aspect-ratio: 1;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  border-right: 1px solid var(--text-primary);
  border-bottom: 1px solid var(--text-primary);
}

.cell.white {
  background-color: var(--surface-color);
}

.cell.black {
  background-color: var(--text-primary);
}

.cell-selected {
  outline: 3px solid var(--primary-color);
  outline-offset: -1px;
  z-index: 1;
  background-color: var(--cell-selected-bg);
}

.cell-highlighted {
  background-color: var(--cell-highlighted-bg);
}
```

#### Clues

```css
.clue {
  display: flex;
  padding: var(--spacing-sm);
  gap: var(--spacing-sm);
  font-size: var(--crossword-font-xl);
  border-radius: var(--radius-sm);
}

#clue-selected {
  background-color: var(--clue-selected-bg);
  outline: 1px solid var(--clue-selected-border);
}

.clue-filled {
  text-decoration: line-through;
  opacity: 0.6;
}
```

### Navigation

#### Header

```css
#header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm);
  border-bottom: 1px solid var(--border-color);
  gap: var(--spacing-sm);
}
```

#### Back Button / Home Icon

```css
.home-icon,
.back-button {
  cursor: pointer;
  color: var(--primary-color);
  font-size: var(--font-sm);
  transition: color 0.2s ease-in-out;
}

.home-icon:hover,
.back-button:hover {
  color: var(--text-primary);
}
```

### Tags & Badges

#### Upgrade Tag

```css
.tag-upgraded {
  background-color: var(--accent-teal);
  color: white;
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--radius-sm);
  font-size: var(--font-xs);
  font-weight: 600;
  position: absolute;
  top: -4px;
  right: -4px;
}
```

#### Count Badge

```css
.badge-count {
  background-color: var(--surface-color);
  color: var(--text-primary);
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--radius-sm);
  font-size: var(--font-xs);
  font-weight: 600;
  border: 1px solid var(--border-color);
}
```

---

## Interactive States

### Hover States

- **Buttons**: Darker background, shadow elevation, slight upward translation
- **Cards**: Shadow elevation, upward translation
- **Links**: Color change, underline
- **Icons**: Color change, background highlight, scale transform

### Active States

- **Buttons**: Pressed appearance, darker color
- **Toggles**: Active color (yellow), toggle position change
- **Selected cells**: Blue outline, light blue background
- **Selected clues**: Yellow background, amber border

### Focus States

- **Inputs**: Blue border, subtle shadow ring
- **Buttons**: Outline or shadow ring
- **Links**: Underline or color change

### Disabled States

```css
.disabled {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
```

---

## Layout Principles

### Container Widths

```css
.home-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--spacing-xl);
}

#grid-container {
  width: min(99vw, 800px);
}
```

### Grid Layouts

#### Home Page Grid

```css
#crosswords {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: var(--spacing-xl);
}
```

**Responsive**:

- Desktop: Multiple columns (auto-fit)
- Mobile: Single column

### Flexbox Patterns

- **Header**: `justify-content: space-between`
- **Button groups**: `justify-content: center`, `gap: var(--spacing-md)`
- **Form fields**: `flex-direction: column`, `gap: var(--spacing-lg)`

### Spacing Between Sections

- **Page sections**: `margin-top: var(--spacing-2xl)`
- **Card groups**: `gap: var(--spacing-xl)`
- **Related elements**: `gap: var(--spacing-md)`

---

## Animation & Transitions

### Transition Timing

```css
transition: all 0.2s ease-in-out; /* Standard transitions */
```

**Duration**: `0.2s` for most interactions
**Easing**: `ease-in-out` for smooth, natural motion

### Keyframe Animations

#### Slide In From Right

```css
@keyframes slideInFromRight {
  0% {
    background-position: left bottom;
  }
  100% {
    background-position: right bottom;
  }
}
```

**Usage**: Countdown button progress animation

#### Skeleton Loading

```css
@keyframes skeleton-loading {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
```

**Usage**: Loading state placeholders

#### Spin

```css
@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
```

**Usage**: Loading spinners

### Transform Effects

- **Hover lift**: `transform: translateY(-2px)`
- **Scale on hover**: `transform: scale(1.1)`
- **Button press**: `transform: translateY(-1px)`

---

## Responsive Design

### Breakpoints

```css
/* Mobile First Approach */

/* Small devices (default) */
/* Base styles apply */

/* Tablet and up (768px+) */
@media (min-width: 768px) {
  /* Tablet adjustments */
}

/* Desktop (1024px+) */
@media (min-width: 1024px) {
  /* Desktop adjustments */
}
```

### Mobile Optimizations

```css
@media (max-width: 768px) {
  .home-container {
    padding: var(--spacing-lg);
  }

  .home-title {
    font-size: var(--font-4xl);
  }

  #crosswords {
    grid-template-columns: 1fr;
    gap: var(--spacing-lg);
  }

  .series {
    padding: var(--spacing-md);
  }
}
```

### Container-driven layout (no media queries)

Settings and form layouts that should stack on narrow viewports **must not use viewport media queries**. Use container-relative CSS so the layout responds to the container width (e.g. modal or panel), not the viewport.

**Pattern: Settings grid**

- Use CSS Grid with **auto-fit** so columns collapse when the container is narrow:
  - `grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr));`
  - When the container is wide enough, multiple columns (e.g. label | control) sit side by side; when narrow, a single column stacks rows.
- Use **flexible widths** so controls reflow instead of overflowing:
  - Inputs/readonly: `width: 100%; max-width: 9rem; min-width: 0;` so they fill the cell when stacked and cap at 9rem when there is space.
  - Option button groups: `flex-wrap: wrap` on the container and `min-width: min(9rem, 100%)` on each button so buttons wrap and can shrink to full width in a single column.

This keeps behavior consistent in narrow modals, side panels, or viewports without duplicating breakpoints in media queries.

### Touch Targets

- **Minimum size**: 44px × 44px for touch interactions
- **Button padding**: At least `var(--spacing-sm)` on all sides
- **Spacing between touch targets**: At least `var(--spacing-sm)`

---

## Accessibility Guidelines

### Color Contrast

- **Text on background**: Minimum 4.5:1 ratio
- **Large text**: Minimum 3:1 ratio
- **Interactive elements**: Minimum 3:1 ratio

### Focus Indicators

- All interactive elements must have visible focus states
- Use `outline` or `box-shadow` for focus rings
- Ensure focus indicators meet WCAG contrast requirements

### Semantic HTML

- Use proper heading hierarchy (h1 → h2 → h3)
- Use semantic elements (`<nav>`, `<main>`, `<section>`, `<article>`)
- Provide alt text for images
- Use ARIA labels where appropriate

### Keyboard Navigation

- All interactive elements must be keyboard accessible
- Logical tab order
- Skip links for main content
- Escape key closes modals/overlays

---

## Usage Examples

### Creating a New Card Component

```css
.my-card {
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: var(--spacing-xl);
  box-shadow: var(--shadow-sm);
  transition: all 0.2s ease-in-out;
}

.my-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}
```

### Creating a Primary Button

```css
.my-button {
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: var(--radius-md);
  padding: var(--spacing-sm) var(--spacing-md);
  font-size: var(--font-base);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.my-button:hover {
  background-color: var(--primary-hover);
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}
```

### Creating a Level Card

```html
<div class="level-card level-card--easy">
  <div class="level-card-header">
    <h3 class="level-card-title">Easy</h3>
    <span class="level-card-tag tag-upgraded">Upgraded</span>
  </div>
  <p class="level-card-description">Easy vocabulary</p>
  <div class="level-card-footer">
    <span class="badge-count">10</span>
    <div class="level-card-preview">
      <!-- 5x5 grid preview -->
    </div>
  </div>
</div>
```

---

## Design Tokens Reference

### Quick Reference

| Token             | Value          | Usage                  |
| ----------------- | -------------- | ---------------------- |
| `--primary-color` | `#2563eb`      | Primary actions, links |
| `--accent-teal`   | `#14b8a6`      | Tags, sliders          |
| `--accent-yellow` | `#fbbf24`      | Toggles, highlights    |
| `--accent-purple` | `#a78bfa`      | Level cards            |
| `--spacing-md`    | `1rem`         | Default spacing        |
| `--radius-md`     | `0.5rem`       | Default radius         |
| `--shadow-md`     | `0 4px 6px...` | Hover elevation        |
| `--font-base`     | `1rem`         | Body text              |

---

## Maintenance & Updates

### Adding New Colors

1. Add to CSS variables in `:root`
2. Document in this guide
3. Update component examples if needed

### Adding New Components

1. Follow existing patterns
2. Use design tokens (colors, spacing, radius)
3. Include hover/focus/active states
4. Document in this guide
5. Ensure responsive behavior

### CSS Conventions

- **Do not use `!important`.** Use specificity and source order to control the cascade. If a style is being overridden, increase selector specificity (e.g. `.cell.cell--selected`) or reorder rules instead of using `!important`.

### Version History

- **v1.0** (Current): Initial comprehensive style guide
  - Color palette with teal, yellow, purple accents
  - Complete component library
  - Responsive guidelines
  - Accessibility standards

---

## Resources

- **CSS Variables**: Defined in `src/main.css`
- **Component Examples**: See `src/Pages/` and `src/Components/`
- **Color Tools**: Use online contrast checkers for accessibility validation

---

_Last updated: [Current Date]_
_Maintained by: Design System Team_
