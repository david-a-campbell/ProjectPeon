#import <Cocoa/Cocoa.h>
@interface PeonRecorder : NSObject
+ (instancetype)sharedRecorder;
+ (BOOL)recordingEnabled;
- (void)toggleRecording:(id)sender;
- (void)beginGameplay;
- (void)finishGameplay;
- (void)finishScorePresentation;
- (void)exportVideo;
- (void)discard;
- (void)captureFrame;
@end
