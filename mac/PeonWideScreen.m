#import "PeonWideScreen.h"
static CGFloat wideAmount;
CGFloat PeonWideScreenAmount(void) { return wideAmount; }
@implementation PeonWideScreen {
    BOOL driving,paused;
    NSRect originalFrame;
}
+ (instancetype)sharedPresentation { static id instance; static dispatch_once_t once; dispatch_once(&once,^{instance=[self new];}); return instance; }
- (void)setDriving:(BOOL)value { driving=value; [self transition]; }
- (void)setPaused:(BOOL)value { paused=value; [self transition]; }
- (void)transition {
    CGFloat target=(driving && !paused) ? 1 : 0;
    if(wideAmount==target) return;
    NSWindow *window=[NSApp.delegate respondsToSelector:@selector(window)] ? [NSApp.delegate valueForKey:@"window"] : nil;
    NSRect startFrame=window.frame,targetFrame=startFrame;
    if(window && !(window.styleMask & NSWindowStyleMaskFullScreen)) {
        if(target && wideAmount==0) originalFrame=startFrame;
        if(target) {
            NSRect visible=window.screen.visibleFrame;
            CGFloat chrome=startFrame.size.height-window.contentView.bounds.size.height;
            CGFloat h=MIN(window.contentView.bounds.size.height,MIN(visible.size.height-chrome,visible.size.width*9/16));
            CGSize content=CGSizeMake(h*16/9,h);
            targetFrame=[window frameRectForContentRect:NSMakeRect(0,0,content.width,content.height)];
            targetFrame.origin=NSMakePoint(NSMidX(startFrame)-targetFrame.size.width/2,NSMidY(startFrame)-targetFrame.size.height/2);
            targetFrame.origin.x=MAX(NSMinX(visible),MIN(targetFrame.origin.x,NSMaxX(visible)-targetFrame.size.width));
            targetFrame.origin.y=MAX(NSMinY(visible),MIN(targetFrame.origin.y,NSMaxY(visible)-targetFrame.size.height));
        } else if(originalFrame.size.width>0) targetFrame=originalFrame;
    }
    wideAmount=target;
    if(window && !(window.styleMask & NSWindowStyleMaskFullScreen)) {
        window.contentAspectRatio=target ? NSMakeSize(16,9) : NSMakeSize(4,3);
        [window setFrame:targetFrame display:YES animate:NO];
    }
}
@end
