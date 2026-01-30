# Responsive Layout Prompt

Create a simple HTML/CSS responsive layout with the following requirements:

## Layout Structure:

1. **HEADER** - Should span the full width of the row below (the container that holds Box 1 and Box 2). When Box 1 and Box 2 are side-by-side, the header spans their combined width. When they stack vertically, the header matches the width of a single box.

2. **BOX 1** - Maximum width of 700px, but should be responsive to the page width (can be smaller if the page is narrower). Takes up available space in its row.

3. **BOX 2** - Same width as BOX 1. Should be positioned on the same row as BOX 1 when there is room (side-by-side), otherwise it should be positioned beneath BOX 1 (stacked vertically).

## Requirements:

- Use modern CSS (flexbox or grid)
- Make it fully responsive
- Box 1 and Box 2 should have equal widths when side-by-side
- The header should dynamically match the width of the Box 1/Box 2 container. It should never be wider than the box 1/box 2 container.
- Include minimal styling to make the boxes visible (borders, padding, background colors)
- Use semantic HTML
- Do not use breakpoints
