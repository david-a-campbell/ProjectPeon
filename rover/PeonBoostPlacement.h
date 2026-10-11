#pragma once
#import "cocos2d.h"

static inline CGRect PeonBoostBounds(CGSize size) {
    CGFloat inset=0;
#ifdef PROJECTPEON_WIDE_UI
    inset=size.width/6;
#endif
    return CGRectMake(-inset,0,size.width+2*inset,size.height);
}
static inline CGPoint PeonClampBoostPosition(CGPoint point,CGSize size) {
    CGRect bounds=PeonBoostBounds(size);
    const CGFloat radius=58.75;
    return ccp(MAX(CGRectGetMinX(bounds)+radius,MIN(CGRectGetMaxX(bounds)-radius,point.x)),
               MAX(radius,MIN(size.height-radius,point.y)));
}
static inline CGPoint PeonDefaultBoostPosition(CGSize size) {
    return PeonClampBoostPosition(ccp(CGRectGetMinX(PeonBoostBounds(size))+150,150),size);
}
