#ifdef PROJECTPEON_MAC
#import "PeonRecorder.h"
#endif
#import "MacAppDelegate.h"
#import "PeonCloseButton.h"
#import "GameManager.h"
#import "BaseGameScene.h"
#import "SaveManager.h"
#import "PeonMac.h"
#import "PeonViewport.h"
#import "PeonInspection.h"
#import "Platforms/Mac/CCGLView.h"

static BOOL keys[128];
static BaseGameScene *inspectionScene(void) {
    CCScene *scene=[[CCDirector sharedDirector] runningScene];
    return [scene isKindOfClass:[BaseGameScene class]] ? (BaseGameScene *)scene : nil;
}
BOOL PeonKeyDown(unsigned short code) { return ![inspectionScene() inspectionCameraEnabled] && code < 128 && keys[code]; }
@interface PeonView : CCGLView { UITouch *pointer; BOOL panningMap; CGPoint previousPanPoint; }
@end
@implementation PeonView
- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event {
    if ([inspectionScene() inspectionCameraEnabled]) {
        [self.openGLContext makeCurrentContext];
        switch(event.keyCode) {
            case 0: case 123: [inspectionScene() panInspectionCameraBy:ccp(128,0)]; break;
            case 2: case 124: [inspectionScene() panInspectionCameraBy:ccp(-128,0)]; break;
            case 13: case 126: [inspectionScene() panInspectionCameraBy:ccp(0,-128)]; break;
            case 1: case 125: [inspectionScene() panInspectionCameraBy:ccp(0,128)]; break;
            case 24: [inspectionScene() zoomInspectionCameraBy:1.2]; break;
            case 27: [inspectionScene() zoomInspectionCameraBy:1/1.2]; break;
            case 53: [inspectionScene() setInspectionCameraEnabled:NO]; break;
            case 35: [[NSApp delegate] performSelector:@selector(saveCameraScreenshot:) withObject:nil]; break;
        }
        return;
    }
    if (event.keyCode<128) keys[event.keyCode]=YES;
    if (!event.isARepeat &&
        !(event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption))) {
        if (event.keyCode==53) {
            [self.openGLContext makeCurrentContext];
            PeonDismissOpenMenu();
        }
        if (event.keyCode==46) [[GameManager sharedGameManager] playNextTrackForCurrentScene];
        if (event.keyCode==15 || event.keyCode==8) {
            CCScene *scene = [[CCDirector sharedDirector] runningScene];
            if ([scene isKindOfClass:[BaseGameScene class]]) {
                [self.openGLContext makeCurrentContext];
                if (event.keyCode==15) [(BaseGameScene *)scene relaunchFromKeyboard];
                else [(BaseGameScene *)scene cartCreationFromKeyboard];
            }
        }
    }
}
- (void)keyUp:(NSEvent *)event { if (event.keyCode<128) keys[event.keyCode]=NO; }
- (void)mouseDown:(NSEvent *)event {
    if ([inspectionScene() inspectionCameraEnabled]) return;
    [self.openGLContext makeCurrentContext];
    CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (!CGRectContainsPoint(PeonGameViewport(self.bounds, [[CCDirector sharedDirector] winSize]), point)) return;
    CGPoint gamePoint=PeonGamePoint(point,PeonGameViewport(self.bounds,[[CCDirector sharedDirector] winSize]),[[CCDirector sharedDirector] winSize]);
    // Keep the top HUD available while the rest of the scene is draggable.
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"PeonMousePan"] && [inspectionScene() drivingCameraAvailable] && gamePoint.y<688) {
        panningMap=YES; previousPanPoint=gamePoint; return;
    }
    [[self window] makeFirstResponder:self];
    [pointer release]; pointer = [UITouch new]; pointer.view = self; pointer.tapCount = event.clickCount;
    pointer.location = [self convertPoint:event.locationInWindow fromView:nil]; pointer.previousLocation = pointer.location;
    [[[CCDirector sharedDirector] touchDispatcher] touchesBegan:[NSSet setWithObject:pointer] withEvent:event];
}
- (void)mouseDragged:(NSEvent *)event {
    [self.openGLContext makeCurrentContext];
    if(panningMap) {
        CGPoint point=PeonGamePoint([self convertPoint:event.locationInWindow fromView:nil],PeonGameViewport(self.bounds,[[CCDirector sharedDirector] winSize]),[[CCDirector sharedDirector] winSize]);
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"PeonMousePan"]) [inspectionScene() panDrivingCameraBy:ccpMult(ccpSub(point,previousPanPoint),2)];
        previousPanPoint=point; return;
    }
    if (!pointer) return;
    pointer.previousLocation=pointer.location; pointer.location=[self convertPoint:event.locationInWindow fromView:nil];
    [[[CCDirector sharedDirector] touchDispatcher] touchesMoved:[NSSet setWithObject:pointer] withEvent:event];
}
- (void)mouseUp:(NSEvent *)event {
    if(panningMap) { panningMap=NO; return; }
    [self.openGLContext makeCurrentContext];
    if (!pointer) return;
    pointer.previousLocation=pointer.location; pointer.location=[self convertPoint:event.locationInWindow fromView:nil];
    [[[CCDirector sharedDirector] touchDispatcher] touchesEnded:[NSSet setWithObject:pointer] withEvent:event];
    [pointer release]; pointer=nil;
}
- (void)cancelInput {
    panningMap=NO;
    memset(keys,0,sizeof(keys));
    if(pointer) { [[[CCDirector sharedDirector] touchDispatcher] touchesCancelled:[NSSet setWithObject:pointer] withEvent:nil]; [pointer release]; pointer=nil; }
}
@end

@implementation AppDelegate
- (void)updateLevelTitle:(NSNotification *)notification {
    NSDictionary *level=notification.object;
    NSInteger planet=[level[@"planet"] integerValue];
    NSArray *names=@[@"Earth",@"Moon",@"Mars"];
    self.levelTitleLabel.stringValue=(planet>=1 && planet<=names.count) ?
        [NSString stringWithFormat:@"%@ %02ld",names[planet-1],(long)[level[@"level"] integerValue]] : @"";
}
- (void)toggleInspectionCamera:(NSMenuItem *)item {
    [[(CCGLView *)self.window.contentView openGLContext] makeCurrentContext];
    BaseGameScene *scene=inspectionScene();
    [scene setInspectionCameraEnabled:!scene.inspectionCameraEnabled];
}
- (void)saveCameraScreenshot:(id)sender {
    NSString *name=[NSString stringWithFormat:@"Project Peon Camera %.0f.png",NSDate.date.timeIntervalSince1970*1000];
    PeonRequestScreenshot([[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:name]);
}
- (BOOL)validateMenuItem:(NSMenuItem *)item {
    if(item.action==@selector(toggleUnlockAllLevels:)) {
        item.state=[[NSUserDefaults standardUserDefaults] boolForKey:@"PeonUnlockAllLevels"]?NSControlStateValueOn:NSControlStateValueOff;
        return YES;
    }
    if(item.action==@selector(toggleMousePan:)) {
        item.state=[[NSUserDefaults standardUserDefaults] boolForKey:@"PeonMousePan"]?NSControlStateValueOn:NSControlStateValueOff;
        return YES;
    }
    if(item.action==@selector(toggleInspectionCamera:)) {
        item.state=inspectionScene().inspectionCameraEnabled?NSControlStateValueOn:NSControlStateValueOff;
        return inspectionScene()!=nil;
    }
    if(item.action==@selector(saveCameraScreenshot:)) return inspectionScene().inspectionCameraEnabled;
    return YES;
}

- (void)toggleFPS:(NSMenuItem *)item {
    BOOL hidden=![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonHideFPS"];
    [[NSUserDefaults standardUserDefaults] setBool:hidden forKey:@"PeonHideFPS"];
    item.state=hidden ? NSControlStateValueOff : NSControlStateValueOn;
}
- (void)toggleMousePan:(NSMenuItem *)item {
    BOOL enabled=![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonMousePan"];
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"PeonMousePan"];
    item.state=enabled?NSControlStateValueOn:NSControlStateValueOff;
}
- (void)toggleUnlockAllLevels:(NSMenuItem *)item {
    [[(CCGLView *)self.window.contentView openGLContext] makeCurrentContext];
    BOOL enabled=![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonUnlockAllLevels"];
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"PeonUnlockAllLevels"];
    item.state=enabled?NSControlStateValueOn:NSControlStateValueOff;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PeonLevelAccessChanged" object:nil];
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"PeonHideFPS":@YES}];
    NSMenu *menu=[[[NSMenu alloc] init] autorelease]; NSMenuItem *root=[[[NSMenuItem alloc] init] autorelease]; [menu addItem:root];
    NSMenu *appMenu=[[[NSMenu alloc] initWithTitle:@"Project Peon"] autorelease]; [root setSubmenu:appMenu];
    [appMenu addItemWithTitle:@"Controls…" action:@selector(showControls:) keyEquivalent:@"?"];
    NSMenuItem *fpsItem=[appMenu addItemWithTitle:@"Show FPS" action:@selector(toggleFPS:) keyEquivalent:@""];
    fpsItem.target=self;
    fpsItem.state=[[NSUserDefaults standardUserDefaults] boolForKey:@"PeonHideFPS"] ? NSControlStateValueOff : NSControlStateValueOn;
    NSMenuItem *panItem=[appMenu addItemWithTitle:@"Mouse Pan Map" action:@selector(toggleMousePan:) keyEquivalent:@""];
    panItem.target=self;
    NSMenuItem *unlockItem=[appMenu addItemWithTitle:@"Unlock All Levels" action:@selector(toggleUnlockAllLevels:) keyEquivalent:@""];
    unlockItem.target=self;
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Project Peon" action:@selector(terminate:) keyEquivalent:@"q"];
    NSMenuItem *debugRoot=[[[NSMenuItem alloc] initWithTitle:@"Camera" action:nil keyEquivalent:@""] autorelease];
    NSMenu *debugMenu=[[[NSMenu alloc] initWithTitle:@"Camera"] autorelease];
    [debugRoot setSubmenu:debugMenu]; [menu addItem:debugRoot];
    NSMenuItem *inspect=[debugMenu addItemWithTitle:@"Inspect Level (WASD / arrows, + / −, Esc to exit)" action:@selector(toggleInspectionCamera:) keyEquivalent:@"i"];
    inspect.target=self; inspect.keyEquivalentModifierMask=NSEventModifierFlagCommand|NSEventModifierFlagOption;
    NSMenuItem *shot=[debugMenu addItemWithTitle:@"Save Screenshot to Desktop" action:@selector(saveCameraScreenshot:) keyEquivalent:@"p"];
    shot.target=self; shot.keyEquivalentModifierMask=NSEventModifierFlagCommand|NSEventModifierFlagOption;
    [NSApp setMainMenu:menu];
    self.window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1365.333333,768) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO] autorelease];
    self.window.title=@"Project Peon — A/D or ←/→ drive · Space boost · R relaunch · C build · M next song"; self.window.delegate=self;
    NSTitlebarAccessoryViewController *levelAccessory=[[[NSTitlebarAccessoryViewController alloc] init] autorelease];
    levelAccessory.layoutAttribute=NSLayoutAttributeRight;
    NSView *levelView=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,112,22)] autorelease];
    self.levelTitleLabel=[NSTextField labelWithString:@""];
    self.levelTitleLabel.frame=NSMakeRect(0,2,100,18);
    self.levelTitleLabel.font=[NSFont boldSystemFontOfSize:12];
    self.levelTitleLabel.textColor=[NSColor secondaryLabelColor];
    self.levelTitleLabel.alignment=NSTextAlignmentRight;
    [levelView addSubview:self.levelTitleLabel];
    levelAccessory.view=levelView;
    [self.window addTitlebarAccessoryViewController:levelAccessory];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLevelTitle:) name:@"PeonLevelTitleChanged" object:nil];
    self.window.contentAspectRatio=NSMakeSize(16,9);
    self.window.contentMinSize=NSMakeSize(640,360);
    [self.window center];
    PeonView *view=[[[PeonView alloc] initWithFrame:NSMakeRect(0,0,1365.333333,768)] autorelease];
    view.wantsBestResolutionOpenGLSurface=YES;
    self.window.contentView=view; [self.window makeKeyAndOrderFront:nil]; [self.window makeFirstResponder:view];
    [view.openGLContext makeCurrentContext];
    CCDirectorMac *director=(CCDirectorMac *)[CCDirector sharedDirector];
    [director setView:view]; [director setProjection:kCCDirectorProjection2D]; [director setAnimationInterval:1.0/60];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    [CCFileUtils sharedFileUtils].enableFallbackSuffixes=NO;
    [SaveManager sharedManager];
    [[GameManager sharedGameManager] setupAudioEngine];
    [[GameManager sharedGameManager] runSceneWithName:TitleSceneID];
    [director startAnimation];
    [NSApp activateIgnoringOtherApps:YES];
}
- (void)showControls:(id)sender {
    NSAlert *alert=[[[NSAlert alloc] init] autorelease]; alert.messageText=@"Project Peon controls";
    alert.informativeText=@"Level selection: move the mouse or use W/A/S/D to move the parallax.\nClick and drag to build your rover.\nA / D or Left / Right arrows: drive\nSpace: booster\nR: relaunch rover\nC: return to cart creation\nM: next music track\nUse the on-screen menus to play, pause, reset and save.\nCommand-Q: quit"; [alert runModal];
}
- (void)applicationWillResignActive:(NSNotification *)n {
    [(PeonView *)self.window.contentView cancelInput];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WILL_RESIGN_ACTIVE object:nil];
    [[CCDirector sharedDirector] pause]; [[GameManager sharedGameManager] resignActive];
}
- (void)applicationDidBecomeActive:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DID_BECOME_ACTIVE object:nil];
    [[CCDirector sharedDirector] resume]; [[GameManager sharedGameManager] becomeActive];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
- (void)applicationWillTerminate:(NSNotification *)n { [[PeonRecorder sharedRecorder] discard]; [self saveContext]; [[CCDirector sharedDirector] end]; }
- (NSURL *)applicationDocumentsDirectory {
    NSString *testDirectory = [[[NSProcessInfo processInfo] environment] objectForKey:@"PEON_SAVE_DIR"];
    if(testDirectory) { NSURL *testURL=[NSURL fileURLWithPath:testDirectory isDirectory:YES]; [[NSFileManager defaultManager] createDirectoryAtURL:testURL withIntermediateDirectories:YES attributes:nil error:NULL]; return testURL; }
    NSURL *url=[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    url=[url URLByAppendingPathComponent:@"Project Peon" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL]; return url;
}
- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) _managedObjectModel=[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"CartSave" withExtension:@"momd"]];
    return _managedObjectModel;
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        _persistentStoreCoordinator=[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        NSError *error=nil;
        if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CartSave.sqlite"] options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
            [NSApp presentError:error]; [NSApp terminate:nil];
        }
    }
    return _persistentStoreCoordinator;
}
- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) { _managedObjectContext=[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]; _managedObjectContext.persistentStoreCoordinator=self.persistentStoreCoordinator; }
    return _managedObjectContext;
}
- (void)saveContext { NSError *error=nil; if (self.managedObjectContext.hasChanges && ![self.managedObjectContext save:&error]) [NSApp presentError:error]; }
@end
int main(int argc,const char *argv[]) {
    @autoreleasepool { freopen([[NSTemporaryDirectory() stringByAppendingPathComponent:@"ProjectPeon.log"] fileSystemRepresentation], "w", stderr); [NSApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular]; AppDelegate *delegate=[AppDelegate new]; NSApp.delegate=delegate; [NSApp run]; [delegate release]; }
    return 0;
}
