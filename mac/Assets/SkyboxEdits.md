# Widescreen skyboxes

Edited with the built-in image generation tool, then composited with the original center using nearest-neighbor scaling. Every center was verified pixel-for-pixel at 3x the original resolution. Final dimensions: 1024x576. Original artwork occupies x=128..895; new artwork occupies the side strips. The renderer compensates for the 3x resolution and left extension to preserve original composition and scale.

Assets (paths relative to rover):
- Planet1/P1L1_P0.png
- Planet1/P1L2_P0.png
- Planet2/P2L1_P0.png
- Planet2/P2L2_P0.png
- Planet2/P2L3_P0.png
- Planet2/P2L5_P0.png
- Planet3/P3L1_P0.png

Prompt applied separately to each original:

> Expand horizontally from 4:3 to exactly 16:9 by outpainting equal amounts on LEFT AND RIGHT only. Keep original full image unchanged in center, occupying middle 75% width and full height. Preserve all original mountains/planet/sun positions, scale, colors, pixel art silhouettes and crisp low-resolution nearest-neighbor style. Continue existing scene seamlessly into new side strips, matching palette and flat pixel shapes. No additional planets, suns, characters, text, UI, borders, blur or new prominent objects. Output a standalone 16:9 landscape skybox. Center must remain unchanged; extend only sides.

Additional Moon P2L2 correction prompt:

> Keep entire central 75% exactly unchanged. Fix only the rightmost 128 pixels: continue the large Earth globe surface and curved circular edge seamlessly into the right strip, aligning features with the existing cut edge. Do not move or resize the planet. Keep its center, colors and artwork locked. Extend the dark blue nebula diagonals smoothly. Flat low-resolution pixel art, original palette, no new objects.

## Seam correction in the renderer

The Earth and Mars landscape skies now draw their original center with mirrored samples from its two edges. This guarantees exact color and silhouette matches at the former 4:3 boundaries; no blending changes the center. The PNGs remain as the original outpainting deliverables. Moon skies continue to use their generated side extensions so the completed Earth globe remains intact. Rendering checks compare every join pixel and the complete unchanged center.
