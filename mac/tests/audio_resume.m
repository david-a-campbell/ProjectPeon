#import "CDAudioManager.h"
#import <objc/runtime.h>
#include <assert.h>

// Control playback deterministically without a sound device or bundled music.
@interface ResumeTestPlayer : AVAudioPlayer
@property BOOL testPlaying, failNextPlay;
@property NSUInteger playCalls;
@end
@implementation ResumeTestPlayer
- (BOOL)isPlaying { return self.testPlaying; }
- (BOOL)play {
    self.playCalls++;
    if (self.failNextPlay) { self.failNextPlay=NO; return NO; }
    self.testPlaying=YES;
    return YES;
}
- (void)pause { self.testPlaying=NO; }
- (void)stop { self.testPlaying=NO; }
@end

int main(void) {
    @autoreleasepool {
        SimpleAudioEngine *engine=[SimpleAudioEngine new];
        ResumeTestPlayer *player=[ResumeTestPlayer alloc];
        object_setIvar(engine, class_getInstanceVariable([SimpleAudioEngine class], "music"), player);
        player.testPlaying=YES;
        [engine pauseAudio];
        [engine pauseAudio];
        assert(!player.isPlaying);
        [engine resumeAudio];
        assert(player.isPlaying && player.playCalls==1);
        [engine resumeAudio];
        assert(player.playCalls==1);

        [engine pauseAudio];
        player.failNextPlay=YES;
        [engine resumeAudio];
        assert(!player.isPlaying);
        [engine resumeAudio];
        assert(player.isPlaying && player.playCalls==3);

        [engine pauseAudio];
        [engine stopBackgroundMusic];
        [engine resumeAudio];
        assert(!player.isPlaying && player.playCalls==3);
        [engine pauseAudio];
        [engine resumeAudio];
        assert(!player.isPlaying && player.playCalls==3);
        puts("Audio resume regression checks passed");
    }
    return 0;
}
