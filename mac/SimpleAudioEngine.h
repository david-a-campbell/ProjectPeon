#import <AVFoundation/AVFoundation.h>
typedef unsigned int ALuint;
@interface SimpleAudioEngine : NSObject <AVAudioPlayerDelegate>
@property float backgroundMusicVolume, effectsVolume;
+ (instancetype)sharedEngine;
- (void)stopBackgroundMusic;
- (BOOL)isBackgroundMusicPlaying;
- (void)preloadBackgroundMusic:(NSString *)file;
- (void)playBackgroundMusic:(NSString *)file loop:(BOOL)loop;
- (void)preloadEffect:(NSString *)file;
- (ALuint)playEffect:(NSString *)file;
- (void)stopEffect:(ALuint)identifier;
- (void)unloadEffect:(NSString *)file;
- (void)pauseAudio;
- (void)resumeAudio;
@end
