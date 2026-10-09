#import <CoreGraphics/CoreGraphics.h>

// Rendering and input share one aspect-fit rectangle in AppKit points.
static inline CGRect PeonGameViewport(CGRect bounds, CGSize gameSize) {
    if (gameSize.width <= 0 || gameSize.height <= 0 || bounds.size.width <= 0 || bounds.size.height <= 0)
        return CGRectZero;
    CGFloat scale = MIN(bounds.size.width/gameSize.width, bounds.size.height/gameSize.height);
    CGSize size = CGSizeMake(gameSize.width*scale, gameSize.height*scale);
    return CGRectMake(CGRectGetMidX(bounds)-size.width/2, CGRectGetMidY(bounds)-size.height/2, size.width, size.height);
}
static inline CGPoint PeonGamePoint(CGPoint point, CGRect viewport, CGSize gameSize) {
    if (viewport.size.width <= 0 || viewport.size.height <= 0) return CGPointZero;
    return CGPointMake((point.x-viewport.origin.x)*gameSize.width/viewport.size.width,
                       (point.y-viewport.origin.y)*gameSize.height/viewport.size.height);
}
static inline CGPoint PeonViewPoint(CGPoint point, CGRect viewport, CGSize gameSize) {
    if (gameSize.width <= 0 || gameSize.height <= 0) return CGPointZero;
    return CGPointMake(viewport.origin.x+point.x*viewport.size.width/gameSize.width,
                       viewport.origin.y+point.y*viewport.size.height/gameSize.height);
}
