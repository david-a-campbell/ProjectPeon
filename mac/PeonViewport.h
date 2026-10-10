#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif
CGFloat PeonWideScreenAmount(void);
#ifdef __cplusplus
}
#endif
static inline CGSize PeonPresentationSize(CGSize gameSize) {
    return CGSizeMake(gameSize.width*(1+PeonWideScreenAmount()/3),gameSize.height);
}

// Rendering and input share one aspect-fit rectangle in AppKit points.
static inline CGRect PeonGameViewport(CGRect bounds, CGSize gameSize) {
    if (gameSize.width <= 0 || gameSize.height <= 0 || bounds.size.width <= 0 || bounds.size.height <= 0)
        return CGRectZero;
    gameSize=PeonPresentationSize(gameSize);
    CGFloat scale = MIN(bounds.size.width/gameSize.width, bounds.size.height/gameSize.height);
    CGSize size = CGSizeMake(gameSize.width*scale, gameSize.height*scale);
    return CGRectMake(CGRectGetMidX(bounds)-size.width/2, CGRectGetMidY(bounds)-size.height/2, size.width, size.height);
}
static inline CGPoint PeonGamePoint(CGPoint point, CGRect viewport, CGSize gameSize) {
    if (viewport.size.width <= 0 || viewport.size.height <= 0) return CGPointZero;
    CGSize presentation=PeonPresentationSize(gameSize);
    return CGPointMake((point.x-viewport.origin.x)*presentation.width/viewport.size.width-(presentation.width-gameSize.width)/2,
                       (point.y-viewport.origin.y)*gameSize.height/viewport.size.height);
}
static inline CGPoint PeonViewPoint(CGPoint point, CGRect viewport, CGSize gameSize) {
    if (gameSize.width <= 0 || gameSize.height <= 0) return CGPointZero;
    CGSize presentation=PeonPresentationSize(gameSize);
    return CGPointMake(viewport.origin.x+(point.x+(presentation.width-gameSize.width)/2)*viewport.size.width/presentation.width,
                       viewport.origin.y+point.y*viewport.size.height/gameSize.height);
}

// Tool icons retain their size while spreading across the wider cart toolbar.
static inline CGFloat PeonCartToolX(CGFloat originalX) {
    return (originalX-512)*4/3+512;
}
