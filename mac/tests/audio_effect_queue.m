#import "CDAudioManager.h"
#import <objc/runtime.h>
#include <assert.h>

@interface NSObject (EffectWorkerTest)
- (void)enqueue:(void (^)(void))work;
@end
@interface EffectTestPlayer : NSObject
@property float volume;
@property(assign) id delegate;
@property BOOL playing;
@property NSUInteger starts, stops;
@property(retain) NSURL *url;
- (BOOL)play;
- (void)pause;
- (void)stop;
@end
@implementation EffectTestPlayer
- (BOOL)play { self.starts++; self.playing=YES; return YES; }
- (void)pause { self.playing=NO; }
- (void)stop { self.stops++; self.playing=NO; }
@end
@interface EffectTestEngine : SimpleAudioEngine
@property(assign) dispatch_semaphore_t gate;
@property(retain) EffectTestPlayer *testPlayer;
@end
@implementation EffectTestEngine
- (AVAudioPlayer *)playerForFile:(NSString *)file {
    assert(!NSThread.isMainThread);
    // Simulate slow decoder preparation. Calls from the game must still return.
    assert(dispatch_semaphore_wait(self.gate, dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC))==0);
    EffectTestPlayer *player=[EffectTestPlayer new];
    player.url=[NSURL fileURLWithPath:file]; self.testPlayer=player;
    return (AVAudioPlayer *)[player autorelease];
}
@end
static void drain(EffectTestEngine *engine) {
    id worker=object_getIvar(engine,class_getInstanceVariable(SimpleAudioEngine.class,"effectWorker"));
    dispatch_semaphore_t done=dispatch_semaphore_create(0);
    [worker enqueue:^{ dispatch_semaphore_signal(done); }];
    assert(dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0);
}
int main(void) { @autoreleasepool {
    EffectTestEngine *engine=[EffectTestEngine new]; engine.gate=dispatch_semaphore_create(0);
    ALuint sound=[engine playEffect:@"whachuuuu.mp3"];
    assert(sound!=0);
    // Queue a stop before preparation finishes; it must follow the pending play.
    [engine stopEffect:sound];
    dispatch_semaphore_signal(engine.gate); drain(engine);
    assert(engine.testPlayer.starts==1 && engine.testPlayer.stops==1);
    assert(!engine.testPlayer.playing);
    assert(engine.testPlayer.volume==0.5f);
    [engine pauseAudio];
    [engine playEffect:@"peon_dizzy.mp3"];
    dispatch_semaphore_signal(engine.gate); drain(engine);
    assert(engine.testPlayer.starts==0);
    engine.effectsVolume=0.4f; [engine resumeAudio]; drain(engine);
    assert(engine.testPlayer.starts==1 && engine.testPlayer.volume==0.2f);
    [engine audioPlayerDidFinishPlaying:(AVAudioPlayer *)engine.testPlayer successfully:YES];
    drain(engine);
    NSDictionary *effects=object_getIvar(engine,class_getInstanceVariable(SimpleAudioEngine.class,"effects"));
    assert(effects.count==0);
    puts("Effect preparation off main thread, queued stop, pause/resume, voice volume, completion: PASS");
} return 0; }
