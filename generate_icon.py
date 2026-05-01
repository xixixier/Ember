#!/usr/bin/env python3
"""Generate Ember app icon - a glowing ember/orange spark on dark background."""

from PIL import Image, ImageDraw
import math

SIZE = 512
CENTER = SIZE // 2

# Ember color palette (matching the app's orange/warm theme)
EMBER_INNER = (255, 160, 50, 255)      # bright orange
EMBER_MID = (255, 100, 20, 255)        # deep orange
EMBER_OUTER = (200, 60, 10, 255)       # dark ember
GLOW_COLOR = (255, 180, 60, 180)        # warm glow
BG_COLOR = (18, 18, 20, 255)            # dark background (matches app dark theme)

def create_icon():
    img = Image.new("RGBA", (SIZE, SIZE), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Draw outer glow (multiple circles with decreasing alpha)
    for r in range(180, 20, -2):
        ratio = (r - 20) / (180 - 20)
        alpha = int(60 * (1 - ratio) ** 2)
        color = (GLOW_COLOR[0], GLOW_COLOR[1], GLOW_COLOR[2], alpha)
        draw.ellipse(
            [CENTER - r, CENTER - r, CENTER + r, CENTER + r],
            fill=color
        )

    # Draw main ember body (3 layered circles for depth)
    # Outer ember
    draw.ellipse(
        [CENTER - 80, CENTER - 80, CENTER + 80, CENTER + 80],
        fill=EMBER_OUTER
    )
    # Mid ember
    draw.ellipse(
        [CENTER - 55, CENTER - 55, CENTER + 55, CENTER + 55],
        fill=EMBER_MID
    )
    # Inner core (brightest)
    draw.ellipse(
        [CENTER - 30, CENTER - 30, CENTER + 30, CENTER + 30],
        fill=EMBER_INNER
    )

    # Draw stylized "spark" lines emanating from the ember
    spark_color = (255, 200, 80, 200)
    for angle in [30, 90, 150, 210, 270, 330]:
        rad = math.radians(angle)
        for length, width in [(100, 3), (80, 2), (60, 1)]:
            alpha = int(200 * (1 - length / 120))
            color = (spark_color[0], spark_color[1], spark_color[2], max(alpha, 30))
            x2 = CENTER + math.cos(rad) * length
            y2 = CENTER + math.sin(rad) * length
            # Draw multiple lines for thickness
            for w in range(-width, width + 1):
                offset_x = -w * math.sin(rad)
                offset_y = w * math.cos(rad)
                draw.line(
                    [(CENTER + offset_x, CENTER + offset_y),
                     (x2 + offset_x, y2 + offset_y)],
                    fill=color,
                    width=1
                )

    # Add subtle outer ring (very thin, glowing)
    ring_color = (255, 140, 40, 80)
    draw.ellipse(
        [CENTER - 95, CENTER - 95, CENTER + 95, CENTER + 95],
        outline=ring_color,
        width=2
    )

    # Save
    output_path = "assets/icon/icon.png"
    import os
    os.makedirs("assets/icon", exist_ok=True)
    img.save(output_path, "PNG")
    print(f"Icon saved to {output_path}")
    return output_path

if __name__ == "__main__":
    create_icon()
