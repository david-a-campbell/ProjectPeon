#pragma once
#import "cocos2d.h"

static inline void PeonInsetBitmapGlyphs(CCLabelBMFont *label) {
    // Keep filtering inside each glyph without changing its layout box.
    for (CCSprite *glyph in label.children) {
        CGRect rect = glyph.textureRect;
        CGSize size = glyph.contentSize;
        [glyph setTextureRect:CGRectInset(rect, 0.5, 0.5)
                     rotated:glyph.textureRectRotated untrimmedSize:size];
    }
}
