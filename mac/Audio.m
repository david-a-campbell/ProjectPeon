#import "CDAudioManager.h"
@implementation CDSoundEngine
+ (void)setMixerSampleRate:(int)rate {}
@end
@implementation CDAudioManager
+ (instancetype)sharedManager { static id instance; static dispatch_once_t once; dispatch_once(&once,^{ instance=[self new]; }); return instance; }
+ (int)sharedManagerState { return kAMStateInitialised; }
+ (void)initAsynchronously:(int)mode { [self sharedManager]; }
- (void)setBackgroundMusicCompletionListener:(id)target selector:(SEL)selector { self.completionTarget=target; self.completionSelector=selector; }
- (void)setResignBehavior:(int)behavior autoHandle:(BOOL)autoHandle {}
- (void)applicationWillResignActive { [[SimpleAudioEngine sharedEngine] pauseAudio]; }
- (void)applicationDidBecomeActive { [[SimpleAudioEngine sharedEngine] resumeAudio]; }
@end
@implementation SimpleAudioEngine { AVAudioPlayer *music; NSMutableDictionary *effects; ALuint nextID; BOOL musicWasPlaying; }
+ (instancetype)sharedEngine { static id instance; static dispatch_once_t once; dispatch_once(&once,^{ instance=[self new]; }); return instance; }
- (id)init { if((self=[super init])) { effects=[NSMutableDictionary new]; _backgroundMusicVolume=1; _effectsVolume=1; } return self; }
- (AVAudioPlayer *)playerForFile:(NSString *)file {
    NSURL *url=[[NSBundle mainBundle] URLForResource:file withExtension:nil]; if(!url) return nil;
    AVAudioPlayer *player=[[[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL] autorelease]; [player prepareToPlay]; return player;
}
- (void)stopBackgroundMusic { [music stop]; musicWasPlaying=NO; }
- (BOOL)isBackgroundMusicPlaying { return music.playing; }
- (void)preloadBackgroundMusic:(NSString *)file {}
- (void)playBackgroundMusic:(NSString *)file loop:(BOOL)loop {
    [music stop]; [music release]; music=[[self playerForFile:file] retain]; music.delegate=self; music.volume=_backgroundMusicVolume; music.numberOfLoops=loop?-1:0; [music play];
}
- (void)preloadEffect:(NSString *)file {}
- (ALuint)playEffect:(NSString *)file {
    @synchronized(self) { AVAudioPlayer *player=[self playerForFile:file]; if(!player) return 0;
        ALuint identifier=++nextID; player.volume=_effectsVolume; player.delegate=self; effects[@(identifier)]=player; [player play]; return identifier; }
}
- (void)stopEffect:(ALuint)identifier { @synchronized(self) { [effects[@(identifier)] stop]; [effects removeObjectForKey:@(identifier)]; } }
- (void)unloadEffect:(NSString *)file {}
- (void)setBackgroundMusicVolume:(float)value { _backgroundMusicVolume=value; music.volume=value; }
- (void)setEffectsVolume:(float)value { @synchronized(self) { _effectsVolume=value; for(AVAudioPlayer *player in effects.allValues) player.volume=value; } }
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if(player==music) { CDAudioManager *manager=[CDAudioManager sharedManager]; if(manager.completionTarget && manager.completionSelector) [manager.completionTarget performSelectorOnMainThread:manager.completionSelector withObject:nil waitUntilDone:NO]; }
    else { @synchronized(self) { for(NSNumber *key in [[effects.allKeys copy] autorelease]) if(effects[key]==player) [effects removeObjectForKey:key]; } }
}
- (void)pauseAudio { musicWasPlaying=music.playing; [music pause]; @synchronized(self) { for(AVAudioPlayer *player in effects.allValues) [player pause]; } }
- (void)resumeAudio { if(musicWasPlaying) [music play]; @synchronized(self) { for(AVAudioPlayer *player in effects.allValues) [player play]; } }
@end
