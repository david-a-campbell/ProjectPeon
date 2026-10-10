#import "PeonWideScreen.h"
// Every presentation now uses the same centered 16:9 logical viewport.
CGFloat PeonWideScreenAmount(void) { return 1; }
@implementation PeonWideScreen
+ (instancetype)sharedPresentation { static id instance; static dispatch_once_t once; dispatch_once(&once,^{instance=[self new];}); return instance; }
- (void)setCartCreation:(BOOL)value {}
- (void)setHomeScreen:(BOOL)value {}
- (void)setLoadingVisible:(BOOL)value {}
- (void)setInstructionsVisible:(BOOL)value {}
- (void)setDriving:(BOOL)value {}
- (void)setPaused:(BOOL)value {}
@end
