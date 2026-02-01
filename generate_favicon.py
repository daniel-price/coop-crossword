#!/usr/bin/env python3
"""
Generate a 5x5 crossword grid favicon.
Second row and second column are white, all other cells are black.
"""

from PIL import Image, ImageDraw

# Create a 32x32 image (standard favicon size, can be scaled)
size = 32
img = Image.new('RGB', (size, size), color='white')
draw = ImageDraw.Draw(img)

# Calculate cell size
cell_size = size // 5
grid_size = 5

# Define colors
black = (0, 0, 0)
white = (255, 255, 255)

# Draw the grid
for row in range(grid_size):
    for col in range(grid_size):
        # Determine if this cell should be white or black
        # Second row (index 1) or second column (index 1) should be white
        is_white = (row == 1) or (col == 1)
        color = white if is_white else black
        
        # Calculate cell position
        x1 = col * cell_size
        y1 = row * cell_size
        x2 = x1 + cell_size
        y2 = y1 + cell_size
        
        # Draw the cell
        draw.rectangle([x1, y1, x2, y2], fill=color)

# Save as favicon
img.save('static/favicon.png', 'PNG')
print("Favicon generated successfully!")
