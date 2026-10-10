#import "PlayerCart.h"
#import "BaseActionLayer.h"
#import "PlayerClipGround.h"
#import "PeonWideScreen.h"
#import "Box2DHelpers.h"
BOOL PeonKeyDown(unsigned short code) __asm("_PeonKeyDown");
BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface BoundaryTestLayer : BaseActionLayer
-(id)initWithWorld:(b2World *)testWorld cart:(PlayerCart *)cart;
-(void)clearStartingCartFromLeftBoundary;
@end
@implementation BoundaryTestLayer
-(id)initWithWorld:(b2World *)testWorld cart:(PlayerCart *)cart {
 if((self=[super init])) { world=testWorld; self.playerCart=cart; }
 return self;
}
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
static void near(double a, double b) { NSCAssert(fabs(a-b)<0.02,@"Boundary mismatch: %f != %f",a,b); }
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



  NSString *maps=[NSString stringWithUTF8String:argv[2]];
  int audited=0;
  for (NSString *planet in @[@"Planet1",@"Planet2",@"Planet3"]) {
   for (int level=1;level<=12;level++) {
    NSString *name=[NSString stringWithFormat:@"planet%@Level%d.tmx",[planet substringFromIndex:6],level];
    NSXMLDocument *xml=[[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[maps stringByAppendingPathComponent:planet] stringByAppendingPathComponent:name]] options:0 error:nil] autorelease];
    NSXMLElement *spawn=[[xml nodesForXPath:@"//object[@type='CartPlayerSprite']" error:nil] firstObject];
    double spawnX=[[spawn attributeForName:@"x"].stringValue doubleValue];
    b2World world(b2Vec2_zero);
    // A legal large wheel whose center is in the expanded build area.
    double wheelX=spawnX-1024.0/6+100;
    PlayerCart *cart=[[[PlayerCart alloc] initWithWorld:&world atLocation:ccp(wheelX,640)] autorelease];
    b2CircleShape wheel; wheel.m_radius=550/pixelsToMeterRatio();
    cart.body->CreateFixture(&wheel,1);
    BoundaryTestLayer *layer=[[[BoundaryTestLayer alloc] initWithWorld:&world cart:cart] autorelease];
    NSArray *clips=[xml nodesForXPath:@"//object[@type='PlayerClip']" error:nil];
    int leftCount=0;
    for(NSXMLElement *element in clips) {
     NSString *clipName=[element attributeForName:@"name"].stringValue;
     NSXMLElement *line=[[element nodesForXPath:@"polyline" error:nil] firstObject];
     NSDictionary *dict=@{@"name":clipName,@"x":@([[element attributeForName:@"x"].stringValue doubleValue]),@"y":@(19200-[[element attributeForName:@"y"].stringValue doubleValue]),@"polylinePoints":[line attributeForName:@"points"].stringValue};
     PlayerClipGround *clip=[[[PlayerClipGround alloc] initWithWorld:&world andDict:dict isSolid:NO] autorelease];
     [layer addChild:clip];
     if([clipName isEqualToString:@"leftClip"]) { leftCount++; near(clip.position.x,-1024.0/6); }
    }
    NSCAssert(leftCount>0,@"Missing map boundary");
    [layer clearStartingCartFromLeftBoundary];
    for(PlayerClipGround *clip in layer.children) {
     if([clip.dictionary[@"name"] isEqualToString:@"leftClip"]) {
      near(clip.position.x,fmin(-1024.0/6,wheelX-550-64));
      near(clip.body->GetPosition().x*pixelsToMeterRatio(),clip.position.x);
     } else near(clip.position.x,[clip.dictionary[@"x"] doubleValue]);
    }
    [layer clearStartingCartFromLeftBoundary];
    cart.body->SetType(b2_dynamicBody);
    for(int step=0;step<30;step++) world.Step(1.0/60,10,8);
    near(cart.body->GetPosition().x*pixelsToMeterRatio(),wheelX);
    near(cart.body->GetLinearVelocity().x,0);
    // A smaller replacement cart returns to the normal wide boundary.
    wheel.m_radius=50/pixelsToMeterRatio();
    cart.body->DestroyFixture(cart.body->GetFixtureList());
    cart.body->CreateFixture(&wheel,1);
    cart.body->SetTransform(b2Vec2((spawnX+512)/pixelsToMeterRatio(),20),0);
    [layer clearStartingCartFromLeftBoundary];
    for(PlayerClipGround *clip in layer.children)
     if([clip.dictionary[@"name"] isEqualToString:@"leftClip"]) near(clip.position.x,-1024.0/6);
    audited++;
   }
  }
  printf("All %d maps: wide left boundary, large-cart clearance, unchanged other boundaries, repeated launch and no startup impulse: PASS\n",audited);
  exit(0);
 }
}
