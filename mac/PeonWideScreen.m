#import "PeonWideScreen.h"
#import <QuartzCore/QuartzCore.h>
static CGFloat wideAmount;
CGFloat PeonWideScreenAmount(void) { return wideAmount; }
@implementation PeonWideScreen {
    BOOL driving,paused;
    NSTimer *transitionTimer;
    CGFloat startAmount,targetAmount;
    CFTimeInterval transitionStart;
}
+ (instancetype)sharedPresentation { static id instance; static dispatch_once_t once; dispatch_once(&once,^{instance=[self new];}); return instance; }
- (void)setDriving:(BOOL)value { driving=value; [self transition]; }
- (void)setPaused:(BOOL)value { paused=value; [self transition]; }
- (void)advanceTransition:(NSTimer *)timer {
    CGFloat progress=MIN(1,MAX(0,(CACurrentMediaTime()-transitionStart)/0.3));
    CGFloat eased=progress*progress*(3-2*progress);
    wideAmount=startAmount+(targetAmount-startAmount)*eased;
    if(progress>=1) {
        wideAmount=targetAmount;
        [transitionTimer invalidate];
        transitionTimer=nil;
    }
}
- (void)transition {
    CGFloat target=(driving && !paused) ? 1 : 0;
    if(transitionTimer && targetAmount==target) return;
    if(!transitionTimer && wideAmount==target) return;
    // Only the aspect-fit game viewport changes. The native window stays 16:9.
    NSWindow *window=[NSApp.delegate respondsToSelector:@selector(window)] ? [NSApp.delegate valueForKey:@"window"] : nil;
    [transitionTimer invalidate];
    transitionTimer=nil;
    targetAmount=target;
    if(!window) { wideAmount=target; return; } // Offscreen inspection has no visible transition.
    startAmount=wideAmount;
    transitionStart=CACurrentMediaTime();
    transitionTimer=[NSTimer timerWithTimeInterval:1.0/60 target:self selector:@selector(advanceTransition:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:transitionTimer forMode:NSRunLoopCommonModes];
}
@end
