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
 NSCAssert(PeonWideScreenAmount()==1,@"App must start in widescreen");
 for (NSNumber *state in @[@YES,@NO,@YES]) {
  [[PeonWideScreen sharedPresentation] setCartCreation:state.boolValue];
  [[PeonWideScreen sharedPresentation] setDriving:!state.boolValue];
  [[PeonWideScreen sharedPresentation] setPaused:state.boolValue];
  [[PeonWideScreen sharedPresentation] setInstructionsVisible:state.boolValue];
  [[PeonWideScreen sharedPresentation] setLoadingVisible:state.boolValue];
  waitForTransition();
  NSCAssert(PeonWideScreenAmount()==1,@"A mode change narrowed the viewport");
  CGSize game=CGSizeMake(1024,768);
  CGRect viewport=PeonGameViewport(delegate.window.contentView.bounds,game);
  CGPoint point=CGPointMake(123,456);
  CGPoint mapped=PeonGamePoint(PeonViewPoint(point,viewport,game),viewport,game);
  NSCAssert(hypot(mapped.x-point.x,mapped.y-point.y)<0.001,@"Pointer mapping changed");
 }
 NSCAssert(NSEqualRects(delegate.window.frame,original),@"Native window moved or resized");
 NSCAssert(delegate.window.contentAspectRatio.width==16 && delegate.window.contentAspectRatio.height==9,@"Native window aspect changed");
 NSLog(@"All modes retain widescreen, pointer alignment and fixed window: PASS");
 NSApp.delegate=nil;
 } return 0; }
