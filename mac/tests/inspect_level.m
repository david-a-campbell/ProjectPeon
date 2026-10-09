#import "PeonInspection.h"
#import "PunkParallax.h"
#import "PeonTerrainEdges.h"
#import "PeonWideScreen.h"
#import "GameManager.h"
#import "SaveMenuItem.h"
#import "UIImage+Extras.h"
#import "SaveManager.h"
#import "PopupMenu.h"
#import "LoadingLayer.h"
#import "LevelSelectLayer.h"
#import "BaseGameScene.h"
#import "CartCreationLayer.h"
@interface RelaunchTestLayer : CartCreationLayer
@property NSInteger relaunchCount;
@property NSInteger creationCount;
@end
@implementation RelaunchTestLayer
- (void)relaunch { self.relaunchCount++; }
- (void)goToCartCreation { self.creationCount++; }
@end
@interface LevelSelectLayer (TestMethods)
-(void)update:(ccTime)dt;
-(void)planetSelected:(int)planet;
@end
#import <objc/runtime.h>
@interface PreviewView : NSObject
@property(retain) NSOpenGLPixelFormat *pixelFormat;
@property(retain) NSOpenGLContext *openGLContext;
@end
@implementation PreviewView
- (void)setMultipleTouchEnabled:(BOOL)enabled {}
- (NSRect)bounds { return NSMakeRect(0,0,1024,768); }
- (NSRect)convertRectToBacking:(NSRect)rect { return rect; }
@end
static BOOL testKeys[128];
static BOOL testMouseInside;
static CGPoint testMouse;
static BOOL mousePosition(id layer, SEL selector, CGPoint *position) {
    *position = testMouse; return testMouseInside;
}
BOOL PeonKeyDown(unsigned short code) { return code<128 && testKeys[code]; }
@interface AuditScene : BaseGameScene
-(void)setupWorld;
@end
@implementation AuditScene
-(void)displayLoadingScreen {}
-(void)loadComplete {}
@end
static void inspectionException(NSException *exception) { fprintf(stderr,"Inspection failed: %s\n",exception.description.UTF8String); exit(1); }
int main(int argc,const char **argv) {
 NSSetUncaughtExceptionHandler(inspectionException);
 @autoreleasepool {
  CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,0};
  CGLPixelFormatObj format; CGLContextObj context; GLint count;
  NSCAssert(CGLChoosePixelFormat(attributes,&format,&count)==kCGLNoError,@"Pixel format");
  NSCAssert(CGLCreateContext(format,NULL,&context)==kCGLNoError,@"Context");
  CGLDestroyPixelFormat(format); CGLSetCurrentContext(context);
  PreviewView *view=[[[PreviewView alloc] init] autorelease];
  NSOpenGLPixelFormatAttribute nativeAttributes[]={NSOpenGLPFAAllowOfflineRenderers,0};
  view.pixelFormat=[[[NSOpenGLPixelFormat alloc] initWithAttributes:nativeAttributes] autorelease];
  view.openGLContext=[[[NSOpenGLContext alloc] initWithCGLContextObj:context] autorelease];
  CCDirector *director=[CCDirector sharedDirector];
  object_setIvar(director,class_getInstanceVariable([CCDirector class],"__view"),view);
  [director setValue:[NSValue valueWithSize:NSMakeSize(1024,768)] forKey:@"_winSizeInPixels"];
  [director setValue:[NSValue valueWithSize:NSMakeSize(1024,768)] forKey:@"_originalWinSize"];
  NSString *resources=@(argv[1]);
  [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[resources stringByAppendingPathComponent:@"menuItemsAtlas.plist"] textureFilename:[resources stringByAppendingPathComponent:@"menuItemsAtlas.png"]];
  [CCFileUtils sharedFileUtils].searchPath=@[resources];
  [CCFileUtils sharedFileUtils].enableFallbackSuffixes=NO;
  for(NSString *atlas in @[@"MainMenuAtlas.plist",@"popupBacking.plist",@"spriteAtlas.plist"]) [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:atlas];
  NSManagedObjectModel *model=[[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[resources stringByAppendingPathComponent:@"CartSave.momd"]]] autorelease];
  NSPersistentStoreCoordinator *coordinator=[[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
  [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
  NSManagedObjectContext *saveContext=[[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
  saveContext.persistentStoreCoordinator=coordinator;
  [[SaveManager sharedManager] setValue:saveContext forKey:@"context"];
  id priorUnlock=[[NSUserDefaults standardUserDefaults] objectForKey:@"PeonUnlockAllLevels"];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PeonUnlockAllLevels"];
  SaveManager *saves=[SaveManager sharedManager];
  int normalPlanet=[saves getHighestPlanetUnlocked];
  NSMutableArray *normalLevels=[NSMutableArray array];
  for(int planet=1;planet<=[saves numberOfPlanets];planet++) [normalLevels addObject:@([saves getHighestLevelUnlockedForPlanet:planet])];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PeonUnlockAllLevels"];
  NSCAssert([saves getHighestPlanetUnlocked]==[saves numberOfPlanets],@"All planets must be accessible");
  for(int planet=1;planet<=[saves numberOfPlanets];planet++) NSCAssert([saves getHighestLevelUnlockedForPlanet:planet]==[saves numberOfLevelsForPlanetNumber:planet],@"All levels must be accessible");
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PeonUnlockAllLevels"];
  NSCAssert([saves getHighestPlanetUnlocked]==normalPlanet,@"Unlock toggle changed saved planet progress");
  for(int planet=1;planet<=[saves numberOfPlanets];planet++) NSCAssert([saves getHighestLevelUnlockedForPlanet:planet]==[normalLevels[planet-1] intValue],@"Unlock toggle changed saved level progress");
  if(priorUnlock) [[NSUserDefaults standardUserDefaults] setObject:priorUnlock forKey:@"PeonUnlockAllLevels"];
  else [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PeonUnlockAllLevels"];
  puts("Unlock-all toggle exposes every level and restores saved progress when disabled: PASS");

  int inspectionPlanet=argc>5?atoi(argv[5]):1;
  [[GameManager sharedGameManager] setCurrentPlanetNum:inspectionPlanet];
  CGRect treeEdge=PeonTerrainVisibleRect(@"P1L3_P5_18.png",CGRectMake(0,0,1280,1280));
  NSCAssert(CGRectGetMaxX(treeEdge)==1016 && treeEdge.size.width>0,@"Transparent tree padding and thin ground tail must be excluded from the join");
  puts("Tree extension joins at visible artwork, excluding transparent padding: PASS");
  [[GameManager sharedGameManager] setCurrentLevelNum:argc>4?atoi(argv[4]):1];
  AuditScene *scene=[AuditScene node];
  [scene setupWorld]; [scene onEnter];
  if(inspectionPlanet==1 && argc>4 && atoi(argv[4])==8) {
   for(CCNode *layer in scene.children) {
    if(![NSStringFromClass(layer.class) isEqualToString:@"BacgroundParallaxLayer"]) continue;
    PunkParallax *parallax=[layer valueForKey:@"parrallaxNode"];
    for(unsigned int i=0;i<parallax.parallaxArray->num;i++) {
     id item=parallax.parallaxArray->arr[i];
     CGPoint ratio,offset;
     [[item valueForKey:@"ratio"] getValue:&ratio];
     [[item valueForKey:@"offset"] getValue:&offset];
     if(fabs(ratio.x-.75)<.00001 && offset.y>=10240)
       NSCAssert(offset.x<=0,@"Upper tree tile must not repeat over unrelated lower tiles");
    }
   }
   puts("Earth 8 upper canopy stays aligned with its own lower tile: PASS");
  }
  NSCAssert(![scene drivingCameraAvailable],@"Mouse pan must be unavailable during cart creation");
  CCNode *drivingLayer=[scene valueForKey:@"inspectionActionLayer"];
  CGPoint beforePan=drivingLayer.position;
  [drivingLayer setValue:@YES forKey:@"shouldFollowSprite"];
  NSCAssert([scene drivingCameraAvailable],@"Mouse pan must be available while driving");
  [scene panDrivingCameraBy:ccp(-128,-32)];
  NSCAssert(!CGPointEqualToPoint(beforePan,drivingLayer.position),@"Mouse drag did not move the camera");
  CGPoint afterPan=drivingLayer.position;
  [drivingLayer setValue:@YES forKey:@"levelWasCompleted"];
  [scene panDrivingCameraBy:ccp(-128,-32)];
  NSCAssert(![scene drivingCameraAvailable] && CGPointEqualToPoint(afterPan,drivingLayer.position),@"Mouse pan must stop at the level ending");
  [drivingLayer setValue:@NO forKey:@"levelWasCompleted"];
  [drivingLayer setValue:@NO forKey:@"shouldFollowSprite"];
  drivingLayer.position=beforePan;
  puts("Mouse pan gated to driving; unavailable in building and results: PASS");
  [scene setInspectionCameraEnabled:YES];
  NSCAssert(scene.inspectionCameraEnabled,@"Inspection did not enable");
  for(CCNode *node in scene.children) if([NSStringFromClass(node.class) isEqualToString:@"CartCreationLayer"] || [NSStringFromClass(node.class) isEqualToString:@"LevelScoreDisplay"]) node.visible=NO;
  NSString *poses=[NSString stringWithContentsOfFile:@(argv[3]) encoding:NSUTF8StringEncoding error:NULL];
  for(NSString *line in [poses componentsSeparatedByString:@"\n"]) {
   NSArray *parts=[line componentsSeparatedByString:@","];
   if(parts.count!=4) continue;
   CGFloat x=[parts[1] doubleValue],y=[parts[2] doubleValue],zoom=[parts[3] doubleValue];
   [scene setInspectionCameraPosition:ccp(512-x*zoom,384-y*zoom) zoom:zoom];
   CCRenderTexture *target=[CCRenderTexture renderTextureWithWidth:1365 height:768];
   [target beginWithClear:0 g:0 b:0 a:1];
   kmMat4 projection;kmMat4OrthographicProjection(&projection,-1024.0/6,1024+1024.0/6,0,768,-1000,1000);
   kmGLMatrixMode(KM_GL_PROJECTION);kmGLLoadMatrix(&projection);
   kmGLMatrixMode(KM_GL_MODELVIEW);kmGLLoadIdentity();
   glDisable(GL_DEPTH_TEST);
   glEnable(GL_BLEND);glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
   [scene visit];
   for(CCNode *layer in scene.children) {
    if(![NSStringFromClass(layer.class) isEqualToString:@"BacgroundParallaxLayer"]) continue;
    PunkParallax *parallax=[layer valueForKey:@"parrallaxNode"];
    for(NSNumber *ratio in @[@.4,@.6,@.675,@.75]) {
     CGFloat left=CGFLOAT_MAX,right=-CGFLOAT_MAX; BOOL present=NO;
     for(unsigned int i=0;i<parallax.parallaxArray->num;i++) {
      id item=parallax.parallaxArray->arr[i];
      CGPoint itemRatio; [[item valueForKey:@"ratio"] getValue:&itemRatio];
      if(fabs(itemRatio.x-ratio.doubleValue)>.00001) continue;
      CCNode *tile=[item valueForKey:@"child"]; CGRect bounds=tile.boundingBox;
      left=MIN(left,CGRectGetMinX(bounds)*parallax.scaleX);
      right=MAX(right,CGRectGetMaxX(bounds)*parallax.scaleX); present=YES;
     }
     if(present) NSCAssert(left<=-1024.0/6+.01 && right>=1024+1024.0/6-.01,@"Terrain edge coverage missing at %@ ratio %@",parts[0],ratio);
    }
   }

   NSString *path=[@(argv[2]) stringByAppendingPathComponent:[parts[0] stringByAppendingString:@".png"]];
   NSCAssert(PeonCaptureScreenshot(path),@"Screenshot failed");
   [target end];
   printf("Captured %s x=%.0f y=%.0f zoom=%.2f\n",[parts[0] UTF8String],x,y,zoom);
  }
  [scene setInspectionCameraEnabled:NO];
  NSCAssert(!scene.inspectionCameraEnabled && PeonWideScreenAmount()==0,@"Inspection did not restore mode");
  puts("Inspection screenshot traversal and restoration: PASS");
 }
 return 0;
}
