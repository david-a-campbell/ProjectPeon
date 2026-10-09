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
  for(NSString *scene in playlists) {
   [manager setValue:scene forKey:@"currentSceneName"];
   [manager playRandomTrackForCurrentScene];
   NSArray *tracks=playlists[scene]; NSUInteger first=[tracks indexOfObject:played];
   NSCAssert(first!=NSNotFound,@"Random song missing");
   for(NSUInteger step=1;step<=tracks.count;step++) {
    [manager playNextTrackForCurrentScene];
    NSCAssert([played isEqual:tracks[(first+step)%tracks.count]],@"Skip did not cycle or wrap correctly");
   }
  }
  manager.musicTracksByScene=[NSMutableDictionary dictionaryWithDictionary:@{@"Empty":@[],@"Single":@[@"one.mp3"]}];
  [manager setValue:@"Single" forKey:@"currentSceneName"]; [manager playNextTrackForCurrentScene];
  NSCAssert([played isEqual:@"one.mp3"],@"Single track failed");
  [manager setValue:@"Empty" forKey:@"currentSceneName"]; [manager playNextTrackForCurrentScene];
  NSCAssert([played isEqual:@"one.mp3"],@"Empty playlist changed playback");
  puts("Music cycling across all scenes, wraparound, random-to-next, single and empty playlists: PASS");
 }
 return 0;
}
