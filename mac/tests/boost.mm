#import "BaseActionLayer.h"
#import "PeonWideScreen.h"
#import "PlayerCart.h"
#import "CartPart.h"
#import "GameManager.h"
#import "SimpleAudioEngine.h"
#import <AVFoundation/AVFoundation.h>
BOOL PeonKeyDown(unsigned short code) __asm("_PeonKeyDown");
BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface BaseActionLayer (BoostTestAccess)
-(void)updateBoostSound;
-(BOOL)hasVisibleBooster;
-(void)boostApplicationInactive:(NSNotification*)notice;
@end
@interface BoostLayer : BaseActionLayer
-(void)start;
@end
@implementation BoostLayer
-(void)start { shouldFollowSprite=YES; }
@end
@interface FuelCart : PlayerCart
@property BOOL usableFuel;
@end
@implementation FuelCart
-(BOOL)hasFuel { return self.usableFuel; }
@end
@interface VisiblePart : CartPart
@property CGRect testBounds;
@end
@implementation VisiblePart
-(CGRect)boundingBox { return self.testBounds; }
@end
@interface SoundSpy : NSObject
@property BOOL playing;
@property double currentTime;
@property float volume;
@property int starts;
@end
@implementation SoundSpy
-(BOOL)isPlaying { return self.playing; }
-(BOOL)play { self.playing=YES; self.starts++; return YES; }
-(void)stop { self.playing=NO; }
@end
@interface PreviewView : NSObject
@property(retain) NSOpenGLPixelFormat *pixelFormat;
@property(retain) NSOpenGLContext *openGLContext;
@end
@implementation PreviewView
- (NSRect)bounds { return NSMakeRect(0,0,1365.333333,768); }
- (NSRect)convertRectToBacking:(NSRect)rect { return rect; }
- (NSUInteger)depthFormat { return 0; }
- (void)setEventDelegate:(id)delegate {}
- (void)setAcceptsTouchEvents:(BOOL)accepts {}
- (void)lockOpenGLContext {}
- (void)unlockOpenGLContext {}
@end

int main(int argc, const char **argv) {
 @autoreleasepool {
  CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,(CGLPixelFormatAttribute)0};
  CGLPixelFormatObj format; CGLContextObj context; GLint count;
  NSCAssert(CGLChoosePixelFormat(attributes,&format,&count)==kCGLNoError,@"Pixel format");
  NSCAssert(CGLCreateContext(format,NULL,&context)==kCGLNoError,@"Context");
  CGLDestroyPixelFormat(format); CGLSetCurrentContext(context);
  [[PeonWideScreen sharedPresentation] setCartCreation:YES];
  PreviewView *view=[[[PreviewView alloc] init] autorelease];
  NSOpenGLPixelFormatAttribute nativeAttributes[]={NSOpenGLPFAAllowOfflineRenderers,0};
  view.pixelFormat=[[[NSOpenGLPixelFormat alloc] initWithAttributes:nativeAttributes] autorelease];
  view.openGLContext=[[[NSOpenGLContext alloc] initWithCGLContextObj:context] autorelease];
  CCDirector *director=[CCDirector sharedDirector];
  NSString *resources=@(argv[1]);
  [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[resources stringByAppendingPathComponent:@"menuItemsAtlas.plist"] textureFilename:[resources stringByAppendingPathComponent:@"menuItemsAtlas.png"]];
  [CCFileUtils sharedFileUtils].searchPath=@[resources];
  [CCFileUtils sharedFileUtils].enableFallbackSuffixes=NO;
  [director setView:(CCGLView *)view];



  BoostLayer *layer=[[[BoostLayer alloc] init] autorelease];
  [layer start];
  FuelCart *cart=[[[FuelCart alloc] init] autorelease];
  cart.components=[NSMutableArray array]; cart.usableFuel=YES; layer.playerCart=cart;
  SoundSpy *spy=[[[SoundSpy alloc] init] autorelease];
  [layer setValue:spy forKey:@"boostSoundPlayer"];
  [layer buttonPressBegan];
  NSCAssert(!spy.playing,@"No boosters must be silent");
  VisiblePart *part=[[[VisiblePart alloc] init] autorelease];
  part.gameObjectType=kBoosterPartType; part.testBounds=CGRectMake(100,100,80,30);
  [layer addChild:part]; [cart.components addObject:part];
  [layer updateBoostSound]; NSCAssert(spy.playing && spy.starts==1,@"Visible booster starts sound");
  [layer updateBoostSound]; NSCAssert(spy.starts==1,@"No duplicate playback each frame");
  [layer buttonPressEnded]; NSCAssert(!spy.playing && spy.currentTime==0,@"Release stops and resets");
  cart.usableFuel=NO; [layer buttonPressBegan]; NSCAssert(!spy.playing,@"Empty fuel stays silent");
  cart.usableFuel=YES; [layer updateBoostSound]; NSCAssert(spy.playing,@"Fuel recovery while held resumes");
  cart.usableFuel=NO; [layer updateBoostSound]; NSCAssert(!spy.playing,@"Fuel exhaustion stops");
  cart.usableFuel=YES; part.testBounds=CGRectMake(10000,100,80,30);
  [layer updateBoostSound]; NSCAssert(!spy.playing,@"Detached offscreen booster silent");
  part.testBounds=CGRectMake(100,100,80,30);
  [layer updateBoostSound]; NSCAssert(spy.playing,@"Visible detached booster audible");
  part.visible=NO; [layer updateBoostSound]; NSCAssert(!spy.playing,@"Hidden booster silent");
  part.visible=YES; part.isReadyForRemoval=YES; [layer updateBoostSound]; NSCAssert(!spy.playing,@"Removed booster silent");
  part.isReadyForRemoval=NO;
  VisiblePart *second=[[[VisiblePart alloc] init] autorelease];
  second.gameObjectType=kBooster50PartType; second.testBounds=CGRectMake(10000,100,80,30);
  [layer addChild:second]; [cart.components addObject:second];
  [layer updateBoostSound]; NSCAssert(spy.playing,@"One visible among offscreen boosters sufficient");
  part.testBounds=CGRectMake(10000,100,80,30); [layer updateBoostSound]; NSCAssert(!spy.playing,@"All boosters offscreen stop");
  // Zoom and camera translation affect visibility.
  part.testBounds=CGRectMake(2000,100,80,30); layer.scale=.25;
  [layer updateBoostSound]; NSCAssert(spy.playing,@"Zoomed-in-world booster appears on screen");
  layer.position=ccp(-10000,0); [layer updateBoostSound]; NSCAssert(!spy.playing,@"Camera translation makes booster inaudible");
  layer.position=CGPointZero; layer.scale=1; part.testBounds=CGRectMake(100,100,80,30);
  [[GameManager sharedGameManager] setIsPaused:YES]; [layer updateBoostSound]; NSCAssert(!spy.playing,@"Pause stops");
  [[GameManager sharedGameManager] setIsPaused:NO]; [layer updateBoostSound]; NSCAssert(spy.playing,@"Unpause resumes held boost");
  [layer boostApplicationInactive:nil]; NSCAssert(!spy.playing,@"Background stops");
  [layer buttonPressBegan]; NSCAssert(spy.playing,@"Reactivation starts");
  [layer onExit]; NSCAssert(!spy.playing,@"Scene exit stops");
  AVAudioPlayer *audio=[[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[resources stringByAppendingPathComponent:@"boost.wav"]] error:NULL] autorelease];
  NSCAssert(audio && fabs(audio.duration-15.1)<.001,@"Bundled trimmed sound decodes at expected duration");
  puts("Boost playback, fuel, visibility, detached parts, camera, pause, background, scene exit, audio asset: PASS");
 }
 return 0;
}
