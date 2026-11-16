#import "CDAudioManager.h"

// AVAudioPlayer preparation can block for tens of milliseconds. Give effects
// their own serial thread and run loop, including delegate delivery.
@interface PeonEffectWorker : NSObject { NSThread *thread; }
- (void)enqueue:(void (^)(void))work;
@end
@implementation PeonEffectWorker
- (id)init {
    if ((self=[super init])) {
        thread=[[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        thread.name=@"Peon sound effects";
        [thread start];
    }
    return self;
}
- (void)run {
    @autoreleasepool {
        NSRunLoop *loop=[NSRunLoop currentRunLoop];
        [loop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [loop run];
    }
}
- (void)runBlock:(void (^)(void))work { @autoreleasepool { work(); } }
- (void)enqueue:(void (^)(void))work {
    [self performSelector:@selector(runBlock:) onThread:thread
               withObject:[[work copy] autorelease] waitUntilDone:NO];
}
@end

// Peon voices sit at half the selected effects level, including live slider changes.
static float PeonVoiceGain(AVAudioPlayer *player) {
    NSString *file = player.url.lastPathComponent;
    return ([file isEqualToString:@"peon_dizzy.mp3"] || [file isEqualToString:@"whachuuuu.mp3"]) ? 0.5f : 1.0f;
}

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
@implementation SimpleAudioEngine { AVAudioPlayer *music; NSMutableDictionary *effects; ALuint nextID; BOOL musicWasPlaying; PeonEffectWorker *effectWorker; float effectVolume; BOOL effectsPaused; }
+ (instancetype)sharedEngine { static id instance; static dispatch_once_t once; dispatch_once(&once,^{ instance=[self new]; }); return instance; }
- (id)init { if((self=[super init])) { effects=[NSMutableDictionary new]; effectWorker=[PeonEffectWorker new]; effectVolume=1; _backgroundMusicVolume=1; _effectsVolume=1; } return self; }
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
    if (!file.length) return 0;
    ALuint identifier;
    @synchronized(self) { identifier=++nextID; }
    [effectWorker enqueue:^{
        AVAudioPlayer *player=[self playerForFile:file];
        if (!player) return;
        player.volume=effectVolume*PeonVoiceGain(player);
        player.delegate=self;
        effects[@(identifier)]=player;
        if (!effectsPaused) [player play];
    }];
    return identifier;
}
- (void)stopEffect:(ALuint)identifier {
    [effectWorker enqueue:^{
        [effects[@(identifier)] stop];
        [effects removeObjectForKey:@(identifier)];
    }];
}
- (void)unloadEffect:(NSString *)file {}
- (void)setBackgroundMusicVolume:(float)value { _backgroundMusicVolume=value; music.volume=value; }
- (void)setEffectsVolume:(float)value {
    _effectsVolume=value;
    [effectWorker enqueue:^{
        effectVolume=value;
        for (AVAudioPlayer *player in effects.allValues) player.volume=value*PeonVoiceGain(player);
    }];
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if(player==music) { CDAudioManager *manager=[CDAudioManager sharedManager]; if(manager.completionTarget && manager.completionSelector) [manager.completionTarget performSelectorOnMainThread:manager.completionSelector withObject:nil waitUntilDone:NO]; }
    else { [effectWorker enqueue:^{ for(NSNumber *key in [[effects.allKeys copy] autorelease]) if(effects[key]==player) [effects removeObjectForKey:key]; }]; }
}
- (void)pauseAudio { musicWasPlaying=music.playing; [music pause]; [effectWorker enqueue:^{ effectsPaused=YES; for(AVAudioPlayer *player in effects.allValues) [player pause]; }]; }
- (void)resumeAudio { if(musicWasPlaying) [music play]; [effectWorker enqueue:^{ effectsPaused=NO; for(AVAudioPlayer *player in effects.allValues) [player play]; }]; }
@end
