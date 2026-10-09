#import "SimpleAudioEngine.h"
enum { kAMStateUninitialised, kAMStateInitialised, kAMM_FxPlusMusicIfNoOtherAudio, kAMRBStopPlay, CD_SAMPLE_RATE_MID };
@interface CDSoundEngine : NSObject
+ (void)setMixerSampleRate:(int)rate;
@end
@interface CDAudioManager : NSObject
@property(assign) id completionTarget;
@property SEL completionSelector;
+ (instancetype)sharedManager;
+ (int)sharedManagerState;
+ (void)initAsynchronously:(int)mode;
- (void)setBackgroundMusicCompletionListener:(id)target selector:(SEL)selector;
- (void)setResignBehavior:(int)behavior autoHandle:(BOOL)autoHandle;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;
@end
