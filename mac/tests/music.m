#import "GameManager.h"
#import <objc/runtime.h>
BOOL PeonKeyDown(unsigned short code) { return NO; }
static NSString *played;
static void recordMusic(id engine, SEL selector, NSString *file, BOOL loop) { played=file; }
int main(int argc,const char **argv) {
 @autoreleasepool {
  method_setImplementation(class_getInstanceMethod([SimpleAudioEngine class],@selector(playBackgroundMusic:loop:)),(IMP)recordMusic);
  NSMutableDictionary *playlists=[NSMutableDictionary dictionaryWithContentsOfFile:@(argv[1])];
  NSSet *menuTracks=[NSSet setWithArray:playlists[@"TitleScene"]];
  NSSet *levelTracks=[NSSet setWithArray:playlists[@"Planet1"]];
  NSCAssert(menuTracks.count==8 && levelTracks.count==9,@"Soundtrack counts changed");
  NSCAssert(![menuTracks intersectsSet:levelTracks],@"Menu and gameplay soundtracks overlap");
  NSCAssert([menuTracks isEqual:[NSSet setWithArray:playlists[@"MainMenuScene"]]],@"Level select uses wrong soundtrack");
  for(NSString *planet in @[@"Planet1",@"Planet2",@"Planet3"])
   NSCAssert([levelTracks isEqual:[NSSet setWithArray:playlists[planet]]],@"Gameplay soundtrack mismatch");
  GameManager *manager=[GameManager sharedGameManager]; manager.musicTracksByScene=playlists;
  // Alternate scenes with identical playlists to ensure scene changes preserve progress.
  for(NSArray *scenes in @[@[@"TitleScene",@"MainMenuScene"], @[@"Planet1",@"Planet2",@"Planet3"]]) {
   NSArray *tracks=playlists[scenes[0]];
   NSString *previous=nil;
   for(NSUInteger cycle=0;cycle<30;cycle++) {
    NSMutableSet *seen=[NSMutableSet set];
    for(NSUInteger step=0;step<tracks.count;step++) {
     [manager setValue:scenes[step%scenes.count] forKey:@"currentSceneName"];
     if(step%2) [manager playNextTrackForCurrentScene];
     else [manager playRandomTrackForCurrentScene];
     NSCAssert([tracks containsObject:played],@"Song outside playlist");
     NSCAssert(![seen containsObject:played],@"Repeated song before playlist exhausted");
     NSCAssert(![previous isEqual:played],@"Repeated song at cycle boundary");
     [seen addObject:played]; previous=[[played copy] autorelease];
    }
    NSCAssert(seen.count==tracks.count,@"Playlist did not play every song");
   }
  }
  manager.musicTracksByScene=[NSMutableDictionary dictionaryWithDictionary:@{@"Empty":@[],@"Single":@[@"one.mp3"]}];
  [manager setValue:@"Single" forKey:@"currentSceneName"]; [manager playNextTrackForCurrentScene];
  NSCAssert([played isEqual:@"one.mp3"],@"Single track failed");
  [manager setValue:@"Empty" forKey:@"currentSceneName"]; [manager playNextTrackForCurrentScene];
  NSCAssert([played isEqual:@"one.mp3"],@"Empty playlist changed playback");
  puts("Shuffled cycles, scene changes, manual skips, boundaries, single and empty playlists: PASS");
 }
 return 0;
}
