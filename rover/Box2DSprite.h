//
//  Box2DSprite.h

#import "GameCharacter.h"
#import "Box2D.h"

@interface Box2DSprite : GameCharacter {
    b2Body *body;
}

@property (assign) b2Body *body;

// Return TRUE to accept the mouse joint
// Return FALSE to reject the mouse joint
- (BOOL)mouseJointBegan;
-(b2Vec2)b2VecFromCGPoint:(CGPoint)point;
-(CGPoint)cgpointFromB2Vec2:(b2Vec2)point;
-(void)triangulatePoints:(NSString*)pointsString ontoBody:(b2Body*)aBody withFixtureDef:(b2FixtureDef)fixDef offset:(CGSize)offset flipY:(BOOL)flipY;
-(void)handleContact:(b2Contact*)contact withImpulse:(const b2ContactImpulse*)impulse otherFixture:(b2Fixture*)otherFixture;
-(void)handleContact:(b2Contact*)contact withOldManifold:(const b2Manifold*)oldManifold otherFixture:(b2Fixture*)otherFixture;
-(void)polygonatePoints:(NSString*)pointsString ontoBody:(b2Body*)aBody withFixtureDef:(b2FixtureDef)fixDef offset:(CGSize)offset flipY:(BOOL)flipY forcePolygonation:(BOOL)forced;
-(double)pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint;
-(BOOL)probabilityWithPercent:(int)percent;
-(CGPoint)centerForPolyArray:(NSMutableArray*)polyIn;
@end
