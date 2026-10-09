#import <Cocoa/Cocoa.h>
#ifdef __cplusplus
extern "C" {
#endif
CGFloat PeonWideScreenAmount(void);
#ifdef __cplusplus
}
#endif
@interface PeonWideScreen : NSObject
+ (instancetype)sharedPresentation;
- (void)setCartCreation:(BOOL)cartCreation;
- (void)setHomeScreen:(BOOL)home;
- (void)setLoadingVisible:(BOOL)visible;
- (void)setInstructionsVisible:(BOOL)visible;
- (void)setDriving:(BOOL)driving;
- (void)setPaused:(BOOL)paused;
@end
