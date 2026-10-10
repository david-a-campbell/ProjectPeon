#import "Pod.h"
#import "BaseActionLayer.h"
#import "PlayerClipGround.h"
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
@interface RightBoundaryLayer : BaseActionLayer
-(id)initWithWorld:(b2World *)testWorld;
-(void)clearShipsFromRightBoundary;
@end
@implementation RightBoundaryLayer
-(id)initWithWorld:(b2World *)testWorld {
 if ((self=[super init])) world=testWorld;
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

  int audited=0, moved=0, clipsChecked=0, blocked=0;
  NSString *maps=@(argv[2]);
  for(int planet=1;planet<=3;planet++) for(int level=1;level<=12;level++) {
   NSString *path=[NSString stringWithFormat:@"%@/Planet%d/planet%dLevel%d.tmx",maps,planet,planet,level];
   NSXMLDocument *xml=[[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:0 error:nil] autorelease];
   NSXMLElement *map=xml.rootElement;
   double mapHeight=[[map attributeForName:@"height"].stringValue doubleValue]*[[map attributeForName:@"tileheight"].stringValue doubleValue];
   NSXMLElement *pod=[[xml nodesForXPath:@"//object[@type='PodSprite']" error:nil] firstObject];
   NSMutableDictionary *props=[NSMutableDictionary dictionary];
   for(NSXMLElement *property in [pod nodesForXPath:@"properties/property" error:nil])
    props[[property attributeForName:@"name"].stringValue]=[property attributeForName:@"value"].stringValue;
   CGPoint center=ccp([[pod attributeForName:@"x"].stringValue doubleValue]+[props[@"width"] doubleValue]/2+[props[@"OffsetX"] doubleValue],
                     mapHeight-[[pod attributeForName:@"y"].stringValue doubleValue]+[props[@"height"] doubleValue]/2+[props[@"OffsetY"] doubleValue]);
   b2World world(b2Vec2_zero);
   RightBoundaryLayer *layer=[[[RightBoundaryLayer alloc] initWithWorld:&world] autorelease];
   ShipTestPod *ship=[[[ShipTestPod alloc] initWithWorld:&world atLocation:center andLayer:layer] autorelease];
   [layer addChild:ship];
   CGRect originalBounds=ship.boundingBox;
   CGPoint originalPosition=ship.position, rampPosition=ship.ramp.position;
   NSMutableArray *clips=[NSMutableArray array];
   for(NSXMLElement *element in [xml nodesForXPath:@"//object[@type='PlayerClip']" error:nil]) {
    NSXMLElement *line=[[element nodesForXPath:@"polyline" error:nil] firstObject];
    NSDictionary *dict=@{@"name":[element attributeForName:@"name"].stringValue,@"x":@([[element attributeForName:@"x"].stringValue doubleValue]),@"y":@(mapHeight-[[element attributeForName:@"y"].stringValue doubleValue]),@"polylinePoints":[line attributeForName:@"points"].stringValue};
    PlayerClipGround *clip=[[[PlayerClipGround alloc] initWithWorld:&world andDict:dict isSolid:NO] autorelease];
    [layer addChild:clip]; [clips addObject:clip];
   }
   BOOL needsMove=CGRectGetMaxX(originalBounds)>64000;
   b2AABB finishBounds;
   ship.finish->GetFixtureList()->GetShape()->ComputeAABB(&finishBounds,ship.finish->GetTransform(),0);
   if(finishBounds.lowerBound.x*pixelsToMeterRatio()>64000) blocked++;
   [layer clearShipsFromRightBoundary];
   for(PlayerClipGround *clip in clips) {
    if (![clip.dictionary[@"name"] isEqualToString:@"rightClip"]) continue;
    clipsChecked++;
    NSCAssert(clip.position.x>=64000,@"Wall moved inward");
    b2AABB wallBounds;
    clip.body->GetFixtureList()->GetShape()->ComputeAABB(&wallBounds,clip.body->GetTransform(),0);
    NSCAssert(wallBounds.lowerBound.x*pixelsToMeterRatio()>=CGRectGetMaxX(originalBounds)+63.9,@"Wall cuts into ship in %@",path);
    NSCAssert(wallBounds.lowerBound.x>finishBounds.upperBound.x,@"Wall blocks completion sensor in %@",path);
    for(b2Fixture *fixture=ship.body->GetFixtureList();fixture;fixture=fixture->GetNext()) {
     b2AABB bounds;fixture->GetShape()->ComputeAABB(&bounds,ship.body->GetTransform(),0);
     NSCAssert(wallBounds.lowerBound.x>=bounds.upperBound.x+63.9/pixelsToMeterRatio(),@"Wall cuts into ship physics");
    }
    CGPoint position=clip.position;
    [layer clearShipsFromRightBoundary];
    near(clip.position.x,position.x); near(clip.position.y,position.y);
   }
   near(ship.position.x,originalPosition.x); near(ship.position.y,originalPosition.y);
   near(ship.ramp.position.x,rampPosition.x); near(ship.ramp.position.y,rampPosition.y);
   // A solid cart part can travel into the finish strip without contacting
   // the map wall or being pushed back out of the ship.
   b2PolygonShape *finishShape=(b2PolygonShape *)ship.finish->GetFixtureList()->GetShape();
   b2Vec2 corner=finishShape->m_vertices[0];
   for(int i=1;i<finishShape->GetVertexCount();i++) {
    corner.x=b2Min(corner.x,finishShape->m_vertices[i].x);
    corner.y=b2Min(corner.y,finishShape->m_vertices[i].y);
   }
   b2BodyDef partDefinition; partDefinition.type=b2_dynamicBody;
   partDefinition.position=ship.finish->GetWorldPoint(corner+b2Vec2(50.0/pixelsToMeterRatio(),50.0/pixelsToMeterRatio()));
   b2Body *part=world.CreateBody(&partDefinition);
   b2CircleShape wheel; wheel.m_radius=20.0/pixelsToMeterRatio();
   part->CreateFixture(&wheel,1); part->SetLinearVelocity(b2Vec2(1,0));
   for(int step=0;step<30;step++) world.Step(1.0/60,10,8);
   BOOL reachedFinish=NO;
   for(b2ContactEdge *contact=part->GetContactList();contact;contact=contact->next)
    if(contact->other==ship.finish && contact->contact->IsTouching()) reachedFinish=YES;
   NSCAssert(reachedFinish,@"Cart part cannot touch completion sensor in %@",path);
   near(part->GetPosition().x,partDefinition.position.x+0.5);
   near(part->GetLinearVelocity().x,1);
   [ship resetPod];
   [layer clearShipsFromRightBoundary];
   near(ship.boundingBox.origin.x,originalBounds.origin.x);
   near(ship.boundingBox.origin.y,originalBounds.origin.y);
   if(needsMove) moved++;
   audited++;
  }
  printf("All %d maps, %d right-wall segments: ship/physics/sensor clearance, unchanged landing/ramp, stable reset: PASS (%d ship overlaps; %d blocked sensors before fix)\n",audited,clipsChecked,moved,blocked);
  // The world owns the test bodies until exit; don't schedule another frame.
  exit(0);
 }
}
