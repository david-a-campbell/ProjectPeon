#import "PlayerCart.h"
#import "PeonWideScreen.h"
#import "Box2DHelpers.h"
BOOL PeonKeyDown(unsigned short code) __asm("_PeonKeyDown");
BOOL PeonKeyDown(unsigned short code) { return NO; }
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
static void near(double a, double b) { NSCAssert(fabs(a-b)<0.02,@"Teleport mismatch: %f != %f",a,b); }
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
  PlayerCart *cart=[[[PlayerCart alloc] initWithWorld:&world atLocation:ccp(320,320)] autorelease];
  cart.body->SetType(b2_dynamicBody);
  b2CircleShape circle; circle.m_radius=1;
  cart.body->CreateFixture(&circle,1);
  b2BodyDef definition; definition.type=b2_dynamicBody; definition.userData=cart;
  definition.position=cart.body->GetPosition()+b2Vec2(4,0);
  definition.angle=.4;
  b2Body *wheel=world.CreateBody(&definition); wheel->CreateFixture(&circle,1);
  b2DistanceJointDef joint;
  joint.Initialize(cart.body,wheel,cart.body->GetPosition(),wheel->GetPosition());
  world.CreateJoint(&joint);
  definition.position=b2Vec2(-100,10);
  b2Body *detached=world.CreateBody(&definition); detached->CreateFixture(&circle,1);
  cart.body->SetLinearVelocity(b2Vec2(7,2)); wheel->SetAngularVelocity(5);
  CCNode *camera=[CCNode node]; camera.position=ccp(-500,-100); camera.scale=.5;
  CGPoint destination=[camera convertToNodeSpace:ccp(512,384)];
  [cart teleportToPosition:destination];
  b2Vec2 center=.5f*(cart.body->GetPosition()+wheel->GetPosition());
  near(center.x*pixelsToMeterRatio(),destination.x); near(center.y*pixelsToMeterRatio(),destination.y);
  near(wheel->GetPosition().x-cart.body->GetPosition().x,4);
  near(wheel->GetAngle(),.4);
  near(cart.body->GetLinearVelocity().Length(),0); near(wheel->GetAngularVelocity(),0);
  near(detached->GetPosition().x,-100);
  NSCAssert(world.GetJointCount()==1,@"Teleport destroyed a cart joint");
  world.Step(1.0/60,10,8);
  near((wheel->GetPosition()-cart.body->GetPosition()).Length(),4);
  [cart teleportToPosition:ccp(1000,1000)];
  center=.5f*(cart.body->GetPosition()+wheel->GetPosition());
  near(center.x*pixelsToMeterRatio(),1000); near(center.y*pixelsToMeterRatio(),1000);
  puts("Teleport camera conversion, assembly center, joint preservation, motion reset and detached parts: PASS");
  exit(0);
 }
}
