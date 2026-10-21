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
#if DEBUG && !defined(PROJECTPEON_APP_STORE)
+ (instancetype)sharedScreenRecorder;
@property(nonatomic, readonly, getter=isScreenRecording) BOOL screenRecording;
- (void)startScreenRecording;
- (void)stopScreenRecording;
#endif
@end
