#import <Cocoa/Cocoa.h>
@interface PeonRecorder : NSObject
+ (instancetype)sharedRecorder;
- (void)beginGameplay;
- (void)finishGameplay;
- (void)exportVideo;
- (void)discard;
- (void)captureFrame;
@end
