#import "SaveMenuItem.h"
#import "UIImage+Extras.h"
#import "SaveManager.h"
#import "PopupMenu.h"
#import "ToolTipMenu.h"
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
- (NSRect)bounds { return NSMakeRect(0,0,1024,768); }
@end
static BOOL testKeys[128];
static BOOL testMouseInside;
static CGPoint testMouse;
static BOOL mousePosition(id layer, SEL selector, CGPoint *position) {
    *position = testMouse; return testMouseInside;
}
BOOL PeonKeyDown(unsigned short code) { return code<128 && testKeys[code]; }
int main(int argc,const char **argv) {
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
  for(NSNumber *factor in @[@1,@2]) {
   NSInteger width=512*factor.integerValue,height=384*factor.integerValue;
   NSBitmapImageRep *rep=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width*4 bitsPerPixel:32] autorelease];
   NSImage *image=[[[NSImage alloc] initWithSize:NSMakeSize(512,384)] autorelease]; [image addRepresentation:rep];
   NSImage *scaled=[image imageByScalingProportionallyToSize:NSMakeSize(512,384)];
   NSCAssert(CGImageGetWidth(scaled.CGImage)==512 && CGImageGetHeight(scaled.CGImage)==384,@"Generated image dimensions depend on screen resolution");
   NSCAssert(CGLGetCurrentContext()==context,@"Image scaling changed the GL context");
   SaveMenuItem *item=[[[SaveMenuItem alloc] initWithImage:image andIndex:0] autorelease];
   CCSprite *preview=[item valueForKey:@"savedImage"];
   CCMenuItemSprite *button=[item valueForKey:@"button"];
   CGRect bounds=preview.boundingBox;
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
  NSCAssert(CGRectContainsRect(CGRectMake(0,0,1024,768),spinner.boundingBox),@"Loading icon outside screen");
  NSCAssert(spinner.position.y==78,@"Loading icon uses inverted coordinates");
  [loading performSelector:@selector(fadeOut)];
  [loading showActivityIndicator];
  NSCAssert([loading valueForKey:@"activityIndicatorSprite"]==nil,@"Loading icon reappears after transition");
  puts("Loading icon placement and transition cleanup: PASS");
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
  puts("All popup types: down/up sprites, drag out/back, cancellation, release dismissal; tooltip release: PASS");
 }
 return 0;
}
