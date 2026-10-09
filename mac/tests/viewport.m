#import "PeonWideScreen.h"
#import "PeonMac.h"
#import "PeonViewport.h"
#import <objc/runtime.h>
BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface ViewportView : NSObject
@property NSRect bounds;
@property CGFloat backingScale;
@end
@implementation ViewportView
- (NSRect)convertRectToBacking:(NSRect)rect {
    CGFloat s=self.backingScale;
    return NSMakeRect(rect.origin.x*s,rect.origin.y*s,rect.size.width*s,rect.size.height*s);
}
@end
int main(void) {
 @autoreleasepool {
  CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,0};
  CGLPixelFormatObj format; CGLContextObj context; GLint count;
  if(CGLChoosePixelFormat(attributes,&format,&count)!=kCGLNoError || !format) return 2;
  if(CGLCreateContext(format,NULL,&context)!=kCGLNoError) return 2;
  CGLDestroyPixelFormat(format); CGLSetCurrentContext(context);
  CCDirectorMac *director=(CCDirectorMac *)[CCDirector sharedDirector];
  ViewportView *view=[ViewportView new];
  object_setIvar(director,class_getInstanceVariable([CCDirector class],"__view"),view);
  [[PeonWideScreen sharedPresentation] setCartCreation:YES];
  CGSize game=CGSizeMake(1024,768);
  [director setValue:[NSValue valueWithSize:game] forKey:@"_originalWinSize"];
  // Intentionally stale dimensions: mapping must use the actual view after resizing.
  [director setValue:[NSValue valueWithSize:game] forKey:@"_winSizeInPixels"];
  NSArray *sizes=@[[NSValue valueWithSize:NSMakeSize(1024,768)], [NSValue valueWithSize:NSMakeSize(1440,900)], [NSValue valueWithSize:NSMakeSize(1920,1080)], [NSValue valueWithSize:NSMakeSize(900,1440)]];
  for(NSValue *size in sizes) for(NSNumber *scale in @[@1,@2]) {
   view.bounds=NSMakeRect(0,0,size.sizeValue.width,size.sizeValue.height); view.backingScale=scale.doubleValue;
   [director setViewport]; GLint gl[4]; glGetIntegerv(GL_VIEWPORT,gl);
   NSCAssert(fabs((double)gl[2]/gl[3]-4.0/3)<0.002,@"Fullscreen aspect stretched");
   CGRect viewport=PeonGameViewport(view.bounds,game);
   NSCAssert(gl[0]==lround(viewport.origin.x*view.backingScale) && gl[1]==lround(viewport.origin.y*view.backingScale),@"Viewport misplaced");
   CGPoint targets[]={{0,0},{1024,768},{512,384},{100,650},{900,80}};
   for(int i=0;i<5;i++) {
    CGPoint viewPoint=[director convertToUI:targets[i]];
    CGPoint result=[director convertToLogicalCoordinates:viewPoint];
    NSCAssert(ccpDistance(result,targets[i])<0.001,@"Pointer mapping not inverse of rendering");
   }
   if(viewport.origin.x>0) NSCAssert([director convertToLogicalCoordinates:CGPointMake(0,384)].x<0,@"Side bar maps into game");
   if(viewport.origin.y>0) NSCAssert([director convertToLogicalCoordinates:CGPointMake(512,0)].y<0,@"Bottom bar maps into game");
   printf("%.0f x %.0f at %.0fx: aspect and pointer alignment PASS\n",size.sizeValue.width,size.sizeValue.height,view.backingScale);
  }
  [[PeonWideScreen sharedPresentation] setDriving:YES];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.55]];
  CGRect wide=PeonGameViewport(CGRectMake(0,0,1920,1080),game);
  NSCAssert(fabs(wide.size.width/wide.size.height-16.0/9)<0.001,@"Driving did not expand to 16:9");
  CGPoint center=PeonGamePoint(CGPointMake(960,540),wide,game);
  NSCAssert(fabs(center.x-512)<0.01 && fabs(center.y-384)<0.01,@"Widescreen pointer center moved");
  CGPoint edge=PeonGamePoint(CGPointMake(0,540),wide,game);
  NSCAssert(edge.x<0,@"Widescreen did not reveal additional world space");
  [[PeonWideScreen sharedPresentation] setPaused:YES];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.55]];
  NSCAssert(PeonWideScreenAmount()==1,@"Menu did not retain widescreen background");
  [[PeonWideScreen sharedPresentation] setDriving:NO];
  [[PeonWideScreen sharedPresentation] setPaused:NO];
  puts("Immediate widescreen expansion, pointer alignment and menu collapse: PASS");
 }
 return 0;
}
