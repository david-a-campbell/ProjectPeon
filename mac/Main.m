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
#import "Platforms/Mac/CCGLView.h"

static BOOL keys[128];
BOOL PeonKeyDown(unsigned short code) { return code < 128 && keys[code]; }
@interface PeonView : CCGLView { UITouch *pointer; }
@end
@implementation PeonView
- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event {
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
    [self.openGLContext makeCurrentContext];
    CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (!CGRectContainsPoint(PeonGameViewport(self.bounds, [[CCDirector sharedDirector] winSize]), point)) return;
    [[self window] makeFirstResponder:self];
    [pointer release]; pointer = [UITouch new]; pointer.view = self; pointer.tapCount = event.clickCount;
    pointer.location = [self convertPoint:event.locationInWindow fromView:nil]; pointer.previousLocation = pointer.location;
    [[[CCDirector sharedDirector] touchDispatcher] touchesBegan:[NSSet setWithObject:pointer] withEvent:event];
}
- (void)mouseDragged:(NSEvent *)event {
    [self.openGLContext makeCurrentContext];
    if (!pointer) return;
    pointer.previousLocation=pointer.location; pointer.location=[self convertPoint:event.locationInWindow fromView:nil];
    [[[CCDirector sharedDirector] touchDispatcher] touchesMoved:[NSSet setWithObject:pointer] withEvent:event];
}
- (void)mouseUp:(NSEvent *)event {
    [self.openGLContext makeCurrentContext];
    if (!pointer) return;
    pointer.previousLocation=pointer.location; pointer.location=[self convertPoint:event.locationInWindow fromView:nil];
    [[[CCDirector sharedDirector] touchDispatcher] touchesEnded:[NSSet setWithObject:pointer] withEvent:event];
    [pointer release]; pointer=nil;
}
- (void)cancelInput {
    memset(keys,0,sizeof(keys));
    if(pointer) { [[[CCDirector sharedDirector] touchDispatcher] touchesCancelled:[NSSet setWithObject:pointer] withEvent:nil]; [pointer release]; pointer=nil; }
}
@end

@implementation AppDelegate
- (void)toggleFPS:(NSMenuItem *)item {
    BOOL hidden=![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonHideFPS"];
    [[NSUserDefaults standardUserDefaults] setBool:hidden forKey:@"PeonHideFPS"];
    item.state=hidden ? NSControlStateValueOff : NSControlStateValueOn;
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"PeonHideFPS":@YES}];
    NSMenu *menu=[[[NSMenu alloc] init] autorelease]; NSMenuItem *root=[[[NSMenuItem alloc] init] autorelease]; [menu addItem:root];
    NSMenu *appMenu=[[[NSMenu alloc] initWithTitle:@"Project Peon"] autorelease]; [root setSubmenu:appMenu];
    [appMenu addItemWithTitle:@"Controls…" action:@selector(showControls:) keyEquivalent:@"?"];
    NSMenuItem *fpsItem=[appMenu addItemWithTitle:@"Show FPS" action:@selector(toggleFPS:) keyEquivalent:@""];
    fpsItem.target=self;
    fpsItem.state=[[NSUserDefaults standardUserDefaults] boolForKey:@"PeonHideFPS"] ? NSControlStateValueOff : NSControlStateValueOn;
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Project Peon" action:@selector(terminate:) keyEquivalent:@"q"];
    [NSApp setMainMenu:menu];
    self.window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1024,768) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO] autorelease];
    self.window.title=@"Project Peon — A/D or ←/→ drive · Space boost · R relaunch · C build · M next song"; self.window.delegate=self;
    self.window.contentAspectRatio=NSMakeSize(4,3);
    self.window.contentMinSize=NSMakeSize(640,480);
    [self.window center];
    PeonView *view=[[[PeonView alloc] initWithFrame:NSMakeRect(0,0,1024,768)] autorelease];
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
