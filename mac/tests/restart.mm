#import "BaseActionLayer.h"
#import "Pod.h"
#import "Booster.h"
#import "PlayerCart.h"
#import "LevelScoreDisplay.h"
#import "CartCreationLayer.h"
#import "PeonWideScreen.h"
#import "SaveManager.h"
BOOL PeonKeyDown(unsigned short code) __asm("_PeonKeyDown");
BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface RestartScore : LevelScoreDisplay
@property int saves;
@end
@implementation RestartScore
-(void)saveData { hasPendingScore=NO; self.saves++; }
@end
@interface RestartCamera : BaseActionLayer
@property BOOL beganDriving;
-(void)resetGamePlay;
@end
@implementation RestartCamera
-(void)beginGameplay { shouldFollowSprite=YES; self.beganDriving=YES; }
@end
@interface ResetBooster : Booster
@end
@implementation ResetBooster
-(void)setupFixture {} // This test exercises emitter lifecycle without cart geometry.
@end
@interface FueledCart : PlayerCart
@end
@implementation FueledCart
-(BOOL)hasFuel { return YES; }
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

static void advance(CCActionManager *manager, double seconds) {
 for(int i=0;i<seconds*60;i++) [manager update:1.0/60];
}
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


  NSManagedObjectModel *model=[[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[resources stringByAppendingPathComponent:@"CartSave.momd"]]] autorelease];
  NSPersistentStoreCoordinator *coordinator=[[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
  [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
  NSManagedObjectContext *saveContext=[[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
  saveContext.persistentStoreCoordinator=coordinator;
  [[SaveManager sharedManager] setValue:saveContext forKey:@"context"];
  RestartScore *card=[RestartScore node];
  [card onEnter];
  CCActionManager *manager=director.actionManager;
  CCNode *bodyMenu=[card valueForKey:@"scoreMenu"];
  CCNode *top=[card valueForKey:@"leftPanelTop"];
  for(double delay : {0.0, 8.3, 10.0}) {
   [card showScore:50 peonCount:5 totalPeons:10 timerColor:kStateGreen tmerState:kState5Fade timeElapsed:30];
   advance(manager,delay);
   [card resetDisplay];
   advance(manager,12);
   NSCAssert(fabs(bodyMenu.position.x+871)<.01 && fabs(top.position.x+37)<.01,@"Results returned after reset");
   NSCAssert(![(CCMenu *)bodyMenu isTouchEnabled],@"Hidden card intercepts clicks");
  }
  RestartCamera *camera=[RestartCamera node];
  [camera onEnter];
  [camera setValue:[NSValue valueWithPoint:NSMakePoint(-400,-300)] forKey:@"originalPosition"];
  [camera setValue:[NSValue valueWithPoint:NSMakePoint(-120,-90)] forKey:@"resetPosition"];
  [camera setValue:@20000 forKey:@"mapWidth"];
  CartCreationLayer *menu=[CartCreationLayer node];
  menu.levelScoreDisplay=card;
  [menu setValue:camera forKey:@"cartCreationDelegate"];
  CCMenu *tab=[CCMenu menuWithItems:nil];
  [menu setValue:tab forKey:@"tabMenu"];
  for(NSNumber *restart in @[@YES,@NO]) {
   camera.scale=.2; camera.position=ccp(-9000,-600);
   [camera setValue:@YES forKey:@"levelWasCompleted"];
   [menu setValue:@NO forKey:@"cartCreationEnabled"];
   [menu setValue:@(kPopupTypeGamePlay) forKey:@"popupTypeToShow"];
   tab.opacity=0; tab.touchEnabled=NO;
   [card showScore:50 peonCount:5 totalPeons:10 timerColor:kStateGreen tmerState:kState5Fade timeElapsed:30];
   if(restart.boolValue) [menu relaunchFromKeyboard]; else [menu cartCreationFromKeyboard];
   advance(manager,8);
   NSCAssert(tab.opacity==255 && tab.isTouchEnabled,@"Shortcut did not restore menu tab");
   NSCAssert(fabs(bodyMenu.position.x+871)<.01,@"Shortcut left results visible");
   NSCAssert([[camera valueForKey:@"shouldFollowSprite"] boolValue]==restart.boolValue,@"Wrong follow mode");
   CGPoint expected=restart.boolValue?ccp(-120,-90):ccp(-400,-300);
   NSCAssert(fabs(camera.scale-(restart.boolValue?.35:1))<.001,@"Wrong mode zoom after results");
   NSCAssert(ccpDistance(camera.position,expected)<.01,@"Wrong mode camera after results");
   NSCAssert(![[camera valueForKey:@"levelWasCompleted"] boolValue],@"Completion state survived reset");
  }
  for (NSString *file in @[@"RocketBlast.plist", @"RocketBlastUpgrade.plist"]) {
   ResetBooster *booster=[ResetBooster node];
   FueledCart *fuelCart=[FueledCart node];
   [booster setValue:fuelCart forKey:@"cart"];
   CCParticleSystemQuad *flame=[CCParticleSystemQuad particleWithFile:file];
   [booster setValue:flame forKey:@"blastEmitter"];
   for (NSNumber *hide in @[@YES,@NO]) {
    [booster buttonPressBegan];
    [flame update:0.1];
    NSCAssert(flame.active && flame.particleCount>0,@"Fixture must have a firing flame");
    [booster setValue:@YES forKey:@"ranOutOfFuel"];
    if (hide.boolValue) [booster dissapear]; else [booster resetPart];
    NSCAssert(!flame.active && flame.particleCount==0,@"Flame survived cart transition");
    NSCAssert(![[booster valueForKey:@"shouldFireBooster"] boolValue],@"Boost input survived reset");
    NSCAssert(![[booster valueForKey:@"ranOutOfFuel"] boolValue],@"Fuel latch survived reset");
    [flame update:1];
    NSCAssert(flame.particleCount==0,@"Flame restarted in editor");
   }
  }
  puts("Standard/upgraded booster flames clear on hide/reset and can fire again: PASS");
  // Use real ship/ramp physics: the former camera stub missed dangling ramp bodies.
  b2World world(b2Vec2(0,-10));
  CCLayer *shipLayer=[CCLayer node];
  [shipLayer onEnter];
  Pod *ship=[[[Pod alloc] initWithWorld:&world atLocation:ccp(4000,1500) andLayer:shipLayer] autorelease];
  [shipLayer addChild:ship];
  PlayerCart *cart=[[[PlayerCart alloc] initWithWorld:&world atLocation:ccp(320,320)] autorelease];
  const int bodyCount=world.GetBodyCount(), jointCount=world.GetJointCount();
  for (double delay : {0.0, 0.3, 0.8, 2.0, 4.0}) {
   [ship closeDoor];
   advance(manager,delay);
   [ship resetPod];
   [cart resetCartBody];
   advance(manager,5);
   NSCAssert(world.GetBodyCount()==bodyCount,@"Restart leaked ship/ramp bodies");
   NSCAssert(world.GetJointCount()==jointCount,@"Restart leaked ramp joints");
   CCSprite *door=[ship valueForKey:@"podDoor"];
   NSCAssert(door.opacity==0 && fabs(door.position.x-157.0/(2*SCREEN_SCALE))<.01,@"Closing animation survived reset");
   CCParticleSystem *blast=[ship valueForKey:@"blastEmitter"];
   NSCAssert(!blast.active,@"Cancelled ramp started ship booster");
   world.Step(1.0/60,10,8);
  }
  puts("Interrupted ship completion at 0/0.3/0.8/2/4 seconds: PASS");
  puts("Results reset before/during/after entry, restart and editor camera/zoom: PASS");
 }
}
