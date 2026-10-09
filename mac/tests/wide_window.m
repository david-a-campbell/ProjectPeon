#import "PeonWideScreen.h"
@interface WindowTestDelegate : NSObject <NSApplicationDelegate>
@property(retain) NSWindow *window;
@end
@implementation WindowTestDelegate
@end
int main(void) { @autoreleasepool {
 [NSApplication sharedApplication];
 WindowTestDelegate *delegate=[WindowTestDelegate new]; NSApp.delegate=delegate;
 delegate.window=[[[NSWindow alloc] initWithContentRect:NSMakeRect(100,100,800,600) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO] autorelease];
 delegate.window.contentAspectRatio=NSMakeSize(4,3);
 NSRect original=delegate.window.frame;
 [[PeonWideScreen sharedPresentation] setDriving:YES];
 NSCAssert(PeonWideScreenAmount()==1,@"Expansion did not snap immediately");
 CGSize size=delegate.window.contentView.bounds.size;
 NSCAssert(fabs(size.width/size.height-16.0/9)<0.003,@"Window did not become 16:9");
 [[PeonWideScreen sharedPresentation] setDriving:NO];
 NSCAssert(NSEqualRects(delegate.window.frame,original),@"Window did not restore its previous frame");
 NSCAssert(PeonWideScreenAmount()==0,@"Presentation did not restore 4:3");
 NSLog(@"Immediate window resize and exact frame restoration: PASS");
 NSApp.delegate=nil;
 } return 0; }
