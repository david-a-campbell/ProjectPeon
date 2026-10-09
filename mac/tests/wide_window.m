#import "PeonWideScreen.h"
#import "PeonViewport.h"
@interface WindowTestDelegate : NSObject <NSApplicationDelegate>
@property(retain) NSWindow *window;
@end
@implementation WindowTestDelegate
@end
static void waitForTransition(void) {
 [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
}
int main(void) { @autoreleasepool {
 [NSApplication sharedApplication];
 WindowTestDelegate *delegate=[WindowTestDelegate new]; NSApp.delegate=delegate;
 delegate.window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,1066.666667,600) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO] autorelease];
 delegate.window.contentAspectRatio=NSMakeSize(16,9);
 NSRect original=delegate.window.frame;
 [[PeonWideScreen sharedPresentation] setDriving:YES];
 NSCAssert(PeonWideScreenAmount()==0,@"Expansion must animate from the current viewport");
 [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.12]];
 CGFloat intermediate=PeonWideScreenAmount();
 NSCAssert(intermediate>0 && intermediate<1,@"Viewport did not animate");
 CGSize game=CGSizeMake(1024,768);
 CGRect viewport=PeonGameViewport(delegate.window.contentView.bounds,game);
 CGPoint point=CGPointMake(123,456);
 CGPoint mapped=PeonGamePoint(PeonViewPoint(point,viewport,game),viewport,game);
 NSCAssert(hypot(mapped.x-point.x,mapped.y-point.y)<0.001,@"Pointer mapping changed during animation");
 // Reverse an unfinished transition without jumping or resizing the window.
 [[PeonWideScreen sharedPresentation] setDriving:NO];
 NSCAssert(PeonWideScreenAmount()==intermediate,@"Reversal jumped");
 waitForTransition();
 NSCAssert(PeonWideScreenAmount()==0,@"Presentation did not return to 4:3");
 [[PeonWideScreen sharedPresentation] setDriving:YES]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Presentation did not expand to 16:9");
 [[PeonWideScreen sharedPresentation] setPaused:YES]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Pause menu did not fill the window");
 [[PeonWideScreen sharedPresentation] setPaused:NO]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Resume did not expand");
 [[PeonWideScreen sharedPresentation] setDriving:NO]; waitForTransition();
 [[PeonWideScreen sharedPresentation] setHomeScreen:YES]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Home screen did not use widescreen");
 [[PeonWideScreen sharedPresentation] setPaused:YES]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Home settings did not fill the window");
 [[PeonWideScreen sharedPresentation] setPaused:NO]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Home screen did not restore widescreen");
 [[PeonWideScreen sharedPresentation] setHomeScreen:NO]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==0,@"Planet selection did not restore 4:3");
 [[PeonWideScreen sharedPresentation] setInstructionsVisible:YES]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==1,@"Automatic tutorial did not expand to widescreen");
 [[PeonWideScreen sharedPresentation] setInstructionsVisible:NO]; waitForTransition();
 NSCAssert(PeonWideScreenAmount()==0,@"Tutorial dismissal did not restore cart view");

 NSCAssert(NSEqualRects(delegate.window.frame,original),@"Native window moved or resized");
 NSCAssert(delegate.window.contentAspectRatio.width==16 && delegate.window.contentAspectRatio.height==9,@"Native window aspect changed");
 NSLog(@"Internal viewport animation, reversal, pause/resume and fixed window: PASS");
 NSApp.delegate=nil;
 } return 0; }
