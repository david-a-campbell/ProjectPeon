#import "PeonViewport.h"
#import "PopupSettings.h"
#import "PopupTitleSettings.h"
#import "LevelScoreDisplay.h"
@interface LevelScoreDisplay (PresentationTest)
- (void)slideMenuIn;
@end
#import "PeonRecorder.h"
#import "PeonWideScreen.h"
#import "PeonSkybox.h"
#import "PunkParallax.h"
#import "PeonCloseButton.h"
#import "SaveMenuItem.h"
#import "SaveMenu.h"
#import "UIImage+Extras.h"
#import "SaveManager.h"
#import "PopupMenu.h"
#import "ToolTipMenu.h"
@interface ReentrantActionTest : NSObject
@property(assign) CCActionManager *manager;
@property(assign) id sibling;
@property NSInteger calls;
- (void)closeDuringUpdate;
@end
@implementation ReentrantActionTest
- (void)closeDuringUpdate {
    self.calls++;
    [self.manager update:1.0/60];
    [self.manager removeAllActionsFromTarget:self.sibling];
    [self.manager removeAllActionsFromTarget:self];
}
@end
@interface ToolTipMenu (CloseTest)
-(id)initWithMessage:(NSString *)message plankCount:(int)count;
@end
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
- (NSRect)bounds { return NSMakeRect(0,0,1365.333333,768); }
- (NSRect)convertRectToBacking:(NSRect)rect { return rect; }
- (NSUInteger)depthFormat { return 0; }
- (void)setEventDelegate:(id)delegate {}
- (void)setAcceptsTouchEvents:(BOOL)accepts {}
- (void)lockOpenGLContext {}
- (void)unlockOpenGLContext {}
@end
static BOOL testKeys[128];
static BOOL testMouseInside;
static CGPoint testMouse;
static BOOL mousePosition(id layer, SEL selector, CGPoint *position) {
    *position = testMouse; return testMouseInside;
}
BOOL PeonKeyDown(unsigned short code) { return code<128 && testKeys[code]; }
static void previewException(NSException *exception) { fprintf(stderr,"Preview check failed: %s\n",exception.description.UTF8String); exit(1); }
int main(int argc,const char **argv) {
 NSSetUncaughtExceptionHandler(previewException);
 @autoreleasepool {
  CCActionManager *reentrantManager=[[[CCActionManager alloc] init] autorelease];
  ReentrantActionTest *closingTarget=[[[ReentrantActionTest alloc] init] autorelease];
  NSObject *closingSibling=[[[NSObject alloc] init] autorelease];
  closingTarget.manager=reentrantManager;
  closingTarget.sibling=closingSibling;
  [reentrantManager addAction:[CCCallFunc actionWithTarget:closingTarget selector:@selector(closeDuringUpdate)] target:closingTarget paused:NO];
  [reentrantManager addAction:[CCDelayTime actionWithDuration:1] target:closingSibling paused:NO];
  [reentrantManager update:1.0/60];
  [reentrantManager update:1.0/60];
  NSCAssert(closingTarget.calls==1,@"A nested frame repeated the closing callback");
  NSCAssert([reentrantManager numberOfRunningActionsInTarget:closingTarget]==0 && [reentrantManager numberOfRunningActionsInTarget:closingSibling]==0,@"Closing actions were not cleaned up");
  puts("Nested animation update during menu cleanup: PASS");
  CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,0};
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
  NSCAssert(CGSizeEqualToSize(director.winSize,CGSizeMake(1024,768)),@"Wide startup window changed the UI canvas");
  CGRect menuViewport=PeonGameViewport(view.bounds,CGSizeMake(1024,768));
  NSCAssert(fabs(menuViewport.origin.x)<0.01 && fabs(CGRectGetMaxX(view.bounds)-CGRectGetMaxX(menuViewport)-menuViewport.origin.x)<0.01,@"Menu viewport must fill the window");
  puts("Wide startup retains original UI canvas and full widescreen viewport: PASS");
  for(NSString *atlas in @[@"MainMenuAtlas.plist",@"popupBacking.plist",@"spriteAtlas.plist"]) [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:atlas];
  for (NSString *texture in @[@"P1L1_P1.png", @"P2L2_P1.png", @"P3L1_P1.png"]) {
   PunkParallax *clouds=[PunkParallax node];
   CCSprite *cloud=[CCSprite spriteWithFile:texture];
   cloud.anchorPoint=ccp(0,0); cloud.scale=4;
   [clouds addChild:cloud z:0 parallaxRatio:ccp(.05,.05) positionOffset:ccp(0,0) motionOffset:ccp(-40,0)];
   NSCAssert(clouds.children.count==3,@"Moving sky needs neighbors on both sides");
   for (NSNumber *wide in @[@NO,@YES]) {
    [[PeonWideScreen sharedPresentation] setDriving:wide.boolValue];
    for (NSNumber *zoom in @[@1,@.2]) {
     clouds.scale=zoom.doubleValue;
     for (NSNumber *cameraX in @[@0,@-10000,@-100000]) {
      clouds.position=ccp(cameraX.doubleValue,0);
      for (int step=0;step<4;step++) {
       [clouds update:step==0?0:1000];
       [clouds visit];
       CGFloat inset=wide.boolValue?1024.0/6:0;
       CGFloat covered=-inset;
       NSArray *tiles=[[clouds.children getNSArray] sortedArrayUsingComparator:^NSComparisonResult(CCNode *a,CCNode *b) {
        return a.position.x<b.position.x?NSOrderedAscending:NSOrderedDescending;
       }];
       for (CCNode *tile in tiles) {
        CGRect bounds=tile.boundingBox;
        CGFloat left=bounds.origin.x*clouds.scaleX;
        CGFloat right=CGRectGetMaxX(bounds)*clouds.scaleX;
        if (right<covered) continue;
        NSCAssert(left<=covered+.01,@"Cloud gap: %@",texture);
        covered=MAX(covered,right);
       }
       NSCAssert(covered>=1024+inset,@"Clouds do not cover right edge: %@",texture);
      }
     }
    }
   }
   [clouds cleanup];
  }
  [[PeonWideScreen sharedPresentation] setDriving:NO];
  puts("All moving sky overlays repeat across both edges during camera travel, wrapping and zoom: PASS");
  for(NSString *name in @[@"P1L1_P0.png",@"P1L2_P0.png",@"P3L1_P0.png"]) {
   CCSprite *source=[CCSprite spriteWithFile:name]; [source.texture setAliasTexParameters];
   CCNode *sky=PeonLandscapeSkybox(source);
   CCRenderTexture *surface=[CCRenderTexture renderTextureWithWidth:1024 height:576];
   NSMutableData *actual=[NSMutableData dataWithLength:1024*576*4];
   NSMutableData *expected=[NSMutableData dataWithLength:1024*576*4];
   [surface beginWithClear:0 g:0 b:0 a:1];
   kmMat4 projection;kmMat4OrthographicProjection(&projection,0,1024,0,576,-1000,1000);
   kmGLMatrixMode(KM_GL_PROJECTION);kmGLLoadMatrix(&projection);
   kmGLMatrixMode(KM_GL_MODELVIEW);kmGLLoadIdentity(); glDisable(GL_DEPTH_TEST);
   [sky visit]; glReadPixels(0,0,1024,576,GL_RGBA,GL_UNSIGNED_BYTE,actual.mutableBytes);
   glClear(GL_COLOR_BUFFER_BIT);
   CCSprite *center=[CCSprite spriteWithTexture:source.texture rect:CGRectMake(128,0,768,576)];
   center.anchorPoint=ccp(0,0); center.position=ccp(128,0); [center visit];
   glReadPixels(0,0,1024,576,GL_RGBA,GL_UNSIGNED_BYTE,expected.mutableBytes);
   [surface end];
   unsigned char *a=actual.mutableBytes,*e=expected.mutableBytes;
   for(int y=0;y<576;y++) {
    NSCAssert(memcmp(a+(y*1024+127)*4,a+(y*1024+128)*4,4)==0,@"Sky left join changed: %@",name);
    NSCAssert(memcmp(a+(y*1024+895)*4,a+(y*1024+896)*4,4)==0,@"Sky right join changed: %@",name);
    NSCAssert(memcmp(a+(y*1024+128)*4,e+(y*1024+128)*4,768*4)==0,@"Sky center changed: %@",name);
   }
  }
  puts("Landscape skyboxes: exact edge matches and unchanged center pixels: PASS");
  // Exercise the real director drawing path: font batch nodes must have a parent.
  [director drawScene];
  [director drawScene];
  id previousFPSSetting=[[NSUserDefaults standardUserDefaults] objectForKey:@"PeonHideFPS"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PeonHideFPS"];
  [director drawScene];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PeonHideFPS"];
  [director drawScene];
  if(previousFPSSetting) [[NSUserDefaults standardUserDefaults] setObject:previousFPSSetting forKey:@"PeonHideFPS"];
  else [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PeonHideFPS"];
  puts("Startup drawing with FPS overlay visible and hidden: PASS");
  NSManagedObjectModel *model=[[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[resources stringByAppendingPathComponent:@"CartSave.momd"]]] autorelease];
  NSPersistentStoreCoordinator *coordinator=[[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
  [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
  NSManagedObjectContext *saveContext=[[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
  saveContext.persistentStoreCoordinator=coordinator;
  [[SaveManager sharedManager] setValue:saveContext forKey:@"context"];
  for(NSNumber *factor in @[@1,@2]) for(NSNumber *wideImage in @[@NO,@YES]) {
   NSInteger imageHeight=wideImage.boolValue?288:384;
   NSInteger width=512*factor.integerValue,height=imageHeight*factor.integerValue;
   NSBitmapImageRep *rep=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width*4 bitsPerPixel:32] autorelease];
   NSImage *image=[[[NSImage alloc] initWithSize:NSMakeSize(512,imageHeight)] autorelease]; [image addRepresentation:rep];
   NSImage *scaled=[image imageByScalingProportionallyToSize:NSMakeSize(512,384)];
   NSCAssert(CGImageGetWidth(scaled.CGImage)==512 && CGImageGetHeight(scaled.CGImage)==384,@"Generated image dimensions depend on screen resolution");
   NSCAssert(CGLGetCurrentContext()==context,@"Image scaling changed the GL context");
   SaveMenuItem *item=[[[SaveMenuItem alloc] initWithImage:image andIndex:0] autorelease];
   CCSprite *preview=[item valueForKey:@"savedImage"];
   CCMenuItemSprite *button=[item valueForKey:@"button"];
   CGRect bounds=preview.boundingBox;
   CGRect visiblePreview=CGRectOffset(preview.boundingBox,button.position.x,button.position.y);
   CCMenuItem *loadAction=[item valueForKey:@"saveButton"], *deleteAction=[item valueForKey:@"deleteButton"];
   NSCAssert(fabs(CGRectGetMaxY(loadAction.boundingBox)-CGRectGetMinY(visiblePreview))<0.01 && fabs(CGRectGetMaxY(deleteAction.boundingBox)-CGRectGetMinY(visiblePreview))<0.01,@"Action long edges do not meet preview bottom");
   NSCAssert(fabs(CGRectGetMinX(loadAction.boundingBox)-CGRectGetMinX(visiblePreview))<0.01 && fabs(CGRectGetMaxX(deleteAction.boundingBox)-CGRectGetMaxX(visiblePreview))<0.01,@"Preview actions lost corner alignment");

   NSCAssert(bounds.size.width<=143.37 && bounds.size.height<=107.53,@"Retina preview exceeds banner: %@",NSStringFromRect(bounds));
   NSCAssert(fabs(button.position.x+button.contentSize.width/2)<0.01 && fabs(button.position.y+button.contentSize.height/2)<0.01,@"Frame is not centered");
   NSCAssert(CGRectContainsRect(CGRectMake(0,0,button.contentSize.width,button.contentSize.height),bounds),@"Preview outside frame");
   printf("%ldx preview: PASS (%.2f x %.2f; expanded %.2f x %.2f)\n",(long)factor.integerValue,bounds.size.width,bounds.size.height,bounds.size.width*3,bounds.size.height*3);
  }
  method_setImplementation(class_getInstanceMethod([LevelSelectLayer class],@selector(parallaxMousePosition:)),(IMP)mousePosition);
  LevelSelectLayer *selection=[[[LevelSelectLayer alloc] init] autorelease];
  CCParallaxNode *parallax=[selection valueForKey:@"parallaxNode"];
  CCNode *menu=[selection valueForKey:@"hexLayer"];
  for(NSNumber *planet in @[@1,@1,@2,@2,@3,@3,@1]) {
   [selection planetSelected:planet.intValue];
   [parallax visit];
   CGPoint position=[menu convertToWorldSpace:CGPointZero];
   NSCAssert(fabs(position.x)<0.01 && fabs(position.y)<0.01,@"Planet menu drifted: %@",NSStringFromPoint(position));
  }
  testKeys[2]=YES; testKeys[13]=YES;
  for(int i=0;i<120;i++) [selection update:1.0/60];
  NSCAssert(parallax.position.x>60 && parallax.position.x<=64 && parallax.position.y>44 && parallax.position.y<=48,@"WASD parallax failed or exceeded bounds");
  [parallax visit];
  CGPoint stable=[menu convertToWorldSpace:CGPointZero];
  NSCAssert(fabs(stable.x)<0.01 && fabs(stable.y)<0.01,@"Parallax moved level buttons");
  testKeys[2]=NO; testKeys[13]=NO;
  for(int i=0;i<120;i++) [selection update:1.0/60];
  NSCAssert(ccpLength(parallax.position)<0.01,@"Parallax did not settle");
  testMouseInside=YES; testMouse=CGPointMake(1023,767);
  for(int i=0;i<120;i++) [selection update:1.0/60];
  NSCAssert(parallax.position.x>60 && parallax.position.y>44,@"Mouse hover did not move parallax without a click");
  [parallax visit];
  stable=[menu convertToWorldSpace:CGPointZero];
  NSCAssert(fabs(stable.x)<0.01 && fabs(stable.y)<0.01,@"Mouse hover moved level buttons");
  testMouse=CGPointMake(512,384);
  for(int i=0;i<120;i++) [selection update:1.0/60];
  NSCAssert(ccpLength(parallax.position)<0.01,@"Center mouse did not center parallax");
  testMouseInside=NO;
  [selection cleanup];
  puts("All planet transitions, stationary buttons, bounded WASD, mouse hover without clicks, and centering: PASS");
  RelaunchTestLayer *roverMenu=[RelaunchTestLayer node];
  CCNode *hudTimer=[CCNode node], *hudFuel=[CCNode node], *hudMenu=[CCNode node];
  [roverMenu setValue:hudTimer forKey:@"timer"];
  [roverMenu setValue:hudFuel forKey:@"fuelGauge"];
  [roverMenu setValue:hudMenu forKey:@"tabMenu"];
  [[PeonWideScreen sharedPresentation] setPaused:NO];
  [[PeonWideScreen sharedPresentation] setDriving:YES];
  [roverMenu visit];
  NSCAssert(fabs(hudTimer.position.x-(40-1024.0/6))<0.01 && fabs(hudFuel.position.x-hudTimer.position.x)<0.01,@"Wide left HUD margin");
  NSCAssert(fabs(hudMenu.position.x-(966.5+1024.0/6))<0.01,@"Wide right HUD margin");
  [[PeonWideScreen sharedPresentation] setDriving:NO];
  [roverMenu visit];
  NSCAssert(fabs(hudTimer.position.x-(40-1024.0/6))<0.01 && fabs(hudMenu.position.x-(966.5+1024.0/6))<0.01,@"Cart HUD lost widescreen corner margins");
  puts("Widescreen HUD corner margins and restoration: PASS");
  CCNode *mapCamera=[NSClassFromString(@"BaseActionLayer") node];
  mapCamera.scale=0.5;
  [mapCamera setValue:@YES forKey:@"shouldFollowSprite"];
  [[PeonWideScreen sharedPresentation] setDriving:YES];
  mapCamera.position=ccp(-128,0);
  NSCAssert(fabs(mapCamera.position.x-(-128-1024.0/6))<0.01,@"Wide camera exposed left map boundary");
  mapCamera.position=ccp(-600,0);
  NSCAssert(mapCamera.position.x==-600,@"Wide camera blocked forward travel");
  [[PeonWideScreen sharedPresentation] setDriving:NO];
  [mapCamera setValue:@NO forKey:@"shouldFollowSprite"];
  mapCamera.position=ccp(-128,0);
  NSCAssert(mapCamera.position.x==-128,@"Normal camera position changed");
  puts("Widescreen map left boundary at zoom and forward travel: PASS");
  SaveMenu *wideSave=[[[SaveMenu alloc] init] autorelease];
  CCNode *saveBacking=[wideSave valueForKey:@"blueprints_background"];
  NSCAssert(fabs(saveBacking.contentSize.width*saveBacking.scaleX-1024.0*4/3)<0.01,@"Save background does not span widescreen");
  CCNode *saveLeft=[wideSave valueForKey:@"blueprints_left_1"];
  CCNode *saveRight=[wideSave valueForKey:@"blueprints_right_1"];
  NSCAssert(fabs(saveLeft.position.x-(-23.5-1024.0/6))<0.01 && fabs(saveRight.position.x-(1047.5+1024.0/6))<0.01,@"Save frame edges did not expand symmetrically");
  puts("Cart starting camera unchanged and save frame widened symmetrically: PASS");
  CCRenderTexture *snapshot=[mapCamera performSelector:@selector(takeCartScreenShot)];
  UIImage *snapshotImage=[snapshot getUIImage];
  NSCAssert(fabs((double)CGImageGetWidth(snapshotImage.CGImage)/CGImageGetHeight(snapshotImage.CGImage)-16.0/9)<0.002,@"Cart capture is not widescreen");
  NSCAssert(mapCamera.position.x==-128,@"Snapshot moved the building camera");
  UIImage *thumbnail=[snapshotImage imageByScalingProportionallyToSize:CGSizeMake(512,288)];
  NSCAssert(CGImageGetWidth(thumbnail.CGImage)==512 && CGImageGetHeight(thumbnail.CGImage)==288,@"Saved snapshot dimensions incorrect");
  puts("Full widescreen snapshot and 512 x 288 saved image: PASS");



  BaseGameScene *level=[BaseGameScene node];
  [level setValue:roverMenu forKey:@"creationLayer"];
  [roverMenu setValue:@YES forKey:@"cartCreationEnabled"];
  [roverMenu setValue:@(kPopupTypeGamePlay) forKey:@"popupTypeToShow"];
  [level relaunchFromKeyboard];
  NSCAssert(roverMenu.relaunchCount==0,@"R relaunched while building");
  [roverMenu setValue:@NO forKey:@"cartCreationEnabled"];
  [level relaunchFromKeyboard];
  NSCAssert(roverMenu.relaunchCount==1,@"R did not call menu relaunch during gameplay");
  PopupMenu *blockingPopup=[PopupMenu node]; [level addChild:blockingPopup];
  [level relaunchFromKeyboard];
  NSCAssert(roverMenu.relaunchCount==1,@"R relaunched through a popup");
  [blockingPopup removeFromParentAndCleanup:YES];
  [roverMenu setValue:@(kPopupTypeCartCreation) forKey:@"popupTypeToShow"];
  [level relaunchFromKeyboard];
  NSCAssert(roverMenu.relaunchCount==1,@"R relaunched after gameplay ended");
  puts("Relaunch shortcut routing and gameplay/popup guards: PASS");
  [level cartCreationFromKeyboard];
  NSCAssert(roverMenu.creationCount==0,@"C triggered outside gameplay");
  [roverMenu setValue:@(kPopupTypeGamePlay) forKey:@"popupTypeToShow"];
  [level cartCreationFromKeyboard];
  NSCAssert(roverMenu.creationCount==1,@"C did not call cart creation action");
  [level addChild:blockingPopup]; [level cartCreationFromKeyboard];
  NSCAssert(roverMenu.creationCount==1,@"C triggered through popup");
  [blockingPopup removeFromParentAndCleanup:YES];
  [roverMenu setValue:@YES forKey:@"cartCreationEnabled"];
  [level cartCreationFromKeyboard];
  NSCAssert(roverMenu.creationCount==1,@"C triggered while already building");
  puts("Cart creation shortcut routing and gameplay/popup guards: PASS");
  LoadingLayer *loading=[[[LoadingLayer alloc] initWithPlanetNum:1 LevelNumber:1] autorelease];
  [loading showActivityIndicator];
  CCSprite *spinner=[loading valueForKey:@"activityIndicatorSprite"];
  NSCAssert(CGRectContainsRect(CGRectMake(-1024.0/6,0,1024.0*4/3,768),spinner.boundingBox),@"Loading icon outside screen");
  NSCAssert(spinner.position.y==78,@"Loading icon uses inverted coordinates");
  [[PeonWideScreen sharedPresentation] setLoadingVisible:YES];
  [loading visit];
  NSCAssert(fabs((1024+1024.0/6)-spinner.position.x-78)<0.01,@"Wide loading icon lost its right margin");
  [[PeonWideScreen sharedPresentation] setLoadingVisible:NO];
  [loading visit];
  NSCAssert(fabs(spinner.position.x-(946+1024.0/6))<0.01,@"Loading icon did not follow restored viewport");
  [loading performSelector:@selector(fadeOut)];
  [loading showActivityIndicator];
  NSCAssert([loading valueForKey:@"activityIndicatorSprite"]==nil,@"Loading icon reappears after transition");
  puts("Loading icon placement and transition cleanup: PASS");
  CCTransitionFade *sceneFade=[CCTransitionFade transitionWithDuration:1 scene:[CCScene node]];
  [sceneFade onEnter];
  CCLayerColor *fadeCover=(CCLayerColor *)[sceneFade getChildByTag:0xFADEFADE];
  NSCAssert(fabs(fadeCover.position.x+1024.0/6)<0.01 && fabs(fadeCover.contentSize.width-1024.0*4/3)<0.01 && fadeCover.contentSize.height==768,@"Scene fade leaves uncovered widescreen edges");
  [sceneFade onExit];
  [sceneFade cleanup];
  puts("Scene fade covers the entire 16:9 canvas: PASS");
  for(int type=kPopupTypeLevelSelect;type<=kPopupStore;type++) {
   PopupMenu *popup=[[[PopupMenu alloc] initForType:type andDelegate:nil] autorelease];
   CCSprite *top=[popup valueForKey:@"top"],*bottom=[popup valueForKey:@"bottom"];
   CGRect frame=CGRectUnion(top.boundingBox,bottom.boundingBox);
   NSCAssert(frame.size.width>0 && frame.size.width<1024,@"Popup width exceeds screen");
   NSCAssert(fabs(CGRectGetMidX(frame))<0.01,@"Popup frame is not centered");
   printf("Popup type %d: PASS (centered, width %.2f)\n",type,frame.size.width);
   CCMenu *closeMenu=(CCMenu *)[top getChildByTag:9906];
   CCMenuItemSprite *close=(CCMenuItemSprite *)[closeMenu getChildByTag:9905];
   NSCAssert(close!=nil && close.boundingBox.size.width<=24.01,@"Missing or oversized close icon");
   top.opacity=255;
   UITouch *touch=[[[UITouch alloc] init] autorelease]; touch.view=(NSView *)view;
   touch.location=[director convertToUI:[popup convertToWorldSpace:CGPointZero]];
   [popup ccTouchBegan:touch withEvent:nil];
   NSCAssert(![[popup valueForKey:@"isClosing"] boolValue],@"Body click dismissed menu");
   touch.location=[director convertToUI:[top convertToWorldSpace:close.position]];
   NSCAssert([closeMenu ccTouchBegan:touch withEvent:nil],@"Close button missed press");
   NSCAssert(close.isSelected && close.selectedImage.visible && !close.normalImage.visible,@"Down sprite not displayed");
   NSCAssert(![[popup valueForKey:@"isClosing"] boolValue],@"Menu dismissed on press instead of release");
   CGPoint inside=touch.location;
   touch.location=ccpAdd(inside,ccp(100,0));
   [closeMenu ccTouchMoved:touch withEvent:nil];
   NSCAssert(!close.isSelected && close.normalImage.visible,@"Drag out did not restore up sprite");
   [closeMenu ccTouchEnded:touch withEvent:nil];
   NSCAssert(![[popup valueForKey:@"isClosing"] boolValue],@"Release outside activated close");
   touch.location=inside;[closeMenu ccTouchBegan:touch withEvent:nil];
   [closeMenu ccTouchCancelled:touch withEvent:nil];
   NSCAssert(!close.isSelected && ![[popup valueForKey:@"isClosing"] boolValue],@"Cancelled press activated close");
   [closeMenu ccTouchBegan:touch withEvent:nil];
   touch.location=ccpAdd(inside,ccp(100,0));[closeMenu ccTouchMoved:touch withEvent:nil];
   touch.location=inside;[closeMenu ccTouchMoved:touch withEvent:nil];
   NSCAssert(close.isSelected,@"Drag back did not restore down state");
   [closeMenu ccTouchEnded:touch withEvent:nil];
   NSCAssert([[popup valueForKey:@"isClosing"] boolValue] && !close.isEnabled,@"Release did not dismiss and disable close");
   [popup cleanup];
  }
  ToolTipMenu *tip=[[[ToolTipMenu alloc] initWithMessage:@"Close button test" plankCount:6] autorelease];
  CCSprite *tipTop=[tip valueForKey:@"top"];
  CCMenu *tipCloseMenu=(CCMenu *)[tipTop getChildByTag:9906];
  CCMenuItem *tipClose=(CCMenuItem *)[tipCloseMenu getChildByTag:9905];
  NSCAssert(tipClose!=nil,@"Tooltip missing close button");tipTop.opacity=255;
  UITouch *tipTouch=[[[UITouch alloc] init] autorelease];tipTouch.view=(NSView *)view;
  tipTouch.location=[director convertToUI:[tipTop convertToWorldSpace:tipClose.position]];
  [tipCloseMenu ccTouchBegan:tipTouch withEvent:nil];
  NSCAssert(tipClose.isSelected && ![[tip valueForKey:@"isClosing"] boolValue],@"Tooltip press should only select button");
  [tipCloseMenu ccTouchEnded:tipTouch withEvent:nil];
  NSCAssert([[tip valueForKey:@"isClosing"] boolValue],@"Tooltip close button did not dismiss");
  [tip cleanup];
  id priorRecording=[[NSUserDefaults standardUserDefaults] objectForKey:@"PeonRecordingEnabled"];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PeonRecordingEnabled"];
  LevelScoreDisplay *recordingScore=[[[LevelScoreDisplay alloc] init] autorelease];
  [[PeonWideScreen sharedPresentation] setPaused:NO];
  [[PeonWideScreen sharedPresentation] setDriving:YES];
  [recordingScore visit];
  NSCAssert(fabs(recordingScore.position.x+1024.0/6)<0.01,@"Hidden score assets did not follow left edge");
  [recordingScore slideMenuIn];
  [recordingScore visit];
  NSCAssert(PeonWideScreenAmount()==1 && fabs(recordingScore.position.x+1024.0/6)<0.01,@"Results must retain widescreen and remain anchored to the left edge");
  [recordingScore cleanup];
  puts("Ending score presentation retains widescreen: PASS");
  [[PeonWideScreen sharedPresentation] setDriving:NO];
  [recordingScore visit];
  NSCAssert(fabs(recordingScore.position.x+1024.0/6)<0.01,@"Score assets lost widescreen left alignment");
  puts("Hidden results follow widescreen left edge and restore: PASS");
  CCMenuItem *exportButton=[recordingScore valueForKey:@"videoBtn"];
  NSCAssert(!exportButton.visible && !exportButton.isEnabled,@"Disabled recording exposed export button");
  [[PeonRecorder sharedRecorder] toggleRecording:nil];
  NSCAssert(exportButton.visible && exportButton.isEnabled,@"Enabled recording did not reveal export button");
  [[PeonRecorder sharedRecorder] toggleRecording:nil];
  NSCAssert(!exportButton.visible && !exportButton.isEnabled,@"Recording button did not hide after disabling");
  if(priorRecording) [[NSUserDefaults standardUserDefaults] setObject:priorRecording forKey:@"PeonRecordingEnabled"];
  else [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PeonRecordingEnabled"];
  puts("Recording toggle updates results export visibility: PASS");
  for(Class settingsClass in @[[PopupSettings class],[PopupTitleSettings class]]) {
   for(NSNumber *gameplay in @[@NO,@YES]) {
    id settings=[[[settingsClass alloc] initWithDelegate:nil forGameplay:gameplay.boolValue] autorelease];
    BOOL hasRecordingToggle=NO;
    for(CCNode *node in [settings nodeArray]) if([node getChildByTag:9910]) hasRecordingToggle=YES;
    NSCAssert(hasRecordingToggle==!gameplay.boolValue,@"Recording toggle visibility wrong for %@",settingsClass);
   }
  }
  puts("Recording setting hidden in gameplay, available outside gameplay: PASS");
  for(NSNumber *type in @[@(kPopupTypeCartCreation),@(kPopupTypeGamePlay)]) {
   PopupMenu *phasePopup=[[[PopupMenu alloc] initForType:type.intValue andDelegate:nil] autorelease];
   [phasePopup onEnter];
   [phasePopup switchToMenu:kPopupSettings];
   for(int frame=0;frame<60;frame++) [[director scheduler] update:1.0/60];
   BOOL hasRecordingToggle=NO;
   for(CCNode *node in [[phasePopup valueForKey:@"currentOptions"] nodeArray])
       if([node getChildByTag:9910]) hasRecordingToggle=YES;
   NSCAssert(hasRecordingToggle==(type.intValue==kPopupTypeCartCreation),@"Recording setting must be available while building, hidden after launch");
   [phasePopup onExit]; [phasePopup cleanup];
  }
  puts("Cart-building recording toggle available; driving toggle hidden: PASS");
  CCNode *escapeRoot=[CCNode node];
  director.notificationNode=escapeRoot;
  [escapeRoot onEnter];
  NSCAssert(!PeonDismissOpenMenu(),@"Escape should do nothing without a menu");
  for(int type=0;type<=6;type++) {
   PopupMenu *escapePopup=[[[PopupMenu alloc] initForType:type andDelegate:nil] autorelease];
   [escapeRoot addChild:escapePopup];
   NSCAssert(PeonDismissOpenMenu() && [[escapePopup valueForKey:@"isClosing"] boolValue],@"Escape did not dismiss popup %d",type);
   NSCAssert(!PeonDismissOpenMenu(),@"Escape reactivated a closing menu");
   [escapePopup removeFromParentAndCleanup:YES];
  }
  [escapeRoot onExit]; director.notificationNode=nil;
  puts("Escape dismissal for all seven popup types and no-menu guard: PASS");
  puts("All popup types: down/up sprites, drag out/back, cancellation, release dismissal; tooltip release: PASS");
 }
 return 0;
}
