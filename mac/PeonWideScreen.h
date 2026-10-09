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
- (void)setDriving:(BOOL)driving;
- (void)setPaused:(BOOL)paused;
@end
