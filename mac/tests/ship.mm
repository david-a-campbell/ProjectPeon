#import "Pod.h"
#import "PeonWideScreen.h"
#import "Box2DHelpers.h"
BOOL PeonKeyDown(unsigned short code) __asm("_PeonKeyDown");
BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface ShipTestPod : Pod
-(PodRamp *)ramp;
-(CCSprite *)background;
-(b2Body *)counter;
-(b2Body *)finish;
@end
@implementation ShipTestPod
-(PodRamp *)ramp { return podRamp; }
-(CCSprite *)background { return podBackground; }
-(b2Body *)counter { return counterBody; }
-(b2Body *)finish { return cartTouchBody; }
@end
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
static void near(double a, double b) { NSCAssert(fabs(a-b)<0.02,@"Geometry mismatch: %f != %f",a,b); }
int main(int argc, const char **argv) {
 @autoreleasepool {
  CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,(CGLPixelFormatAttribute)0};
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

  b2World world(b2Vec2(0,-10));
  CCLayer *layer=[CCLayer node];
  CGPoint oldCenter=ccp(9000,1245);
  CCSprite *old=[CCSprite spriteWithFile:@"podForeground.png"];
  old.scale=2*SCREEN_SCALE; old.position=oldCenter;
  CGRect oldBounds=old.boundingBox;
  ShipTestPod *ship=[[[ShipTestPod alloc] initWithWorld:&world atLocation:oldCenter andLayer:layer] autorelease];
  CGRect bounds=ship.boundingBox;
  near(bounds.origin.x,oldBounds.origin.x); near(bounds.origin.y,oldBounds.origin.y);
  near(bounds.size.width,oldBounds.size.width*4/3); near(bounds.size.height,oldBounds.size.height*4/3);
  near(ship.background.scale,old.scale*4/3);
  PodRamp *ramp=ship.ramp;
  near(ramp.scale,old.scale);
  near(ramp.body->GetPosition().x*pixelsToMeterRatio(),bounds.origin.x+168*4/3.0);
  near(ramp.body->GetPosition().y*pixelsToMeterRatio(),bounds.origin.y+349*4/3.0);
  b2Fixture *wall=ship.body->GetFixtureList()->GetNext();
  b2EdgeShape *edge=(b2EdgeShape *)wall->GetShape();
  near(edge->m_vertex1.x,(1865-1010.75)*4/3.0/pixelsToMeterRatio());
  near(edge->m_vertex2.y,(348-1245)*4/3.0/pixelsToMeterRatio());
  for (b2Body *sensor : {ship.counter,ship.finish}) {
   near(sensor->GetPosition().x,ship.position.x/pixelsToMeterRatio());
   near(sensor->GetPosition().y,ship.position.y/pixelsToMeterRatio());
   NSCAssert(sensor->GetFixtureList()->IsSensor(),@"Ship detection must remain a sensor");
   b2PolygonShape *shape=(b2PolygonShape *)sensor->GetFixtureList()->GetShape();
   double lowest=1e9;
   for(int i=0;i<shape->GetVertexCount();i++) lowest=fmin(lowest,shape->m_vertices[i].y);
   near(lowest,(348-1245)*4/3.0/pixelsToMeterRatio());
  }
  CGPoint enlargedCenter=ship.position;
  [ship resetPod]; [ship resetPod];
  near(ship.position.x,enlargedCenter.x); near(ship.position.y,enlargedCenter.y);
  near(ship.boundingBox.origin.x,oldBounds.origin.x); near(ship.boundingBox.origin.y,oldBounds.origin.y);
  near(ship.ramp.scale,old.scale);
  b2PolygonShape *finishShape=(b2PolygonShape *)ship.finish->GetFixtureList()->GetShape();
  double triggerLeft=1e9;
  for(int i=0;i<finishShape->GetVertexCount();i++) triggerLeft=fmin(triggerLeft,finishShape->m_vertices[i].x);
  near(triggerLeft,(1610-1010.75)*4/3.0/pixelsToMeterRatio());
  [ship closeDoor];
  NSCAssert(ship.body->GetFixtureList()->GetShape()->GetType()==b2Shape::e_edge,@"Door fixture missing");
  puts("Ship size, ground anchor, wall/sensor alignment, unchanged ramp size, reset and closing door: PASS");
  // The world owns the test bodies until exit; don't schedule another frame.
  exit(0);
 }
}
