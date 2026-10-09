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
 }
 return 0;
}
