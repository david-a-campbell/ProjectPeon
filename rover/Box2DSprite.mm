//
//  Box2DSprite.mm

#import "Box2DSprite.h"
#import "PRTriangulator.h"
#import "PRRatcliffTriangulator.h"
#import "Box2DHelpers.h"
#import "polypartition.h"
#import "SplashZone.h"
#import "EmitterManager.h"

const float polyFactor = 100.0f;

@implementation Box2DSprite
@synthesize body;

// Override if necessary
- (BOOL)mouseJointBegan
{
    return TRUE;
}

-(void)triangulatePoints:(NSString*)pointsString ontoBody:(b2Body*)aBody withFixtureDef:(b2FixtureDef)fixDef offset:(CGSize)offset
flipY:(BOOL)flipY
{
    NSMutableArray *polygonPoints = [NSMutableArray array];
    id<PRTriangulator> triangulator = [[PRRatcliffTriangulator alloc] init];
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @", "];
    float fX, fY;
    int n;
    int i, k;
    int Ymult = flipY?-1:1;
    
    NSArray *pointsArray;

    if ([pointsString length])
    {
        pointsArray = [pointsString componentsSeparatedByCharactersInSet:characterSet];
        n = pointsArray.count;
        // build polygon verticies;
        for (i = 0, k = 0; i < n; ++k)
        {
            fX = [[pointsArray objectAtIndex:i] floatValue]-offset.width;
            ++i;

            fY = Ymult*[[pointsArray objectAtIndex:i] floatValue]-offset.height;
            ++i;
            [polygonPoints addObject:[NSValue valueWithCGPoint:ccp(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio())]];
        }
        //Triangulate the points in vertArray
        NSArray *triangulatedPoints = [triangulator triangulateVertices:polygonPoints];
        
        b2FixtureDef fixtureDef;
        fixtureDef.filter = fixDef.filter;
        fixtureDef.friction = fixDef.friction;
        fixtureDef.restitution = fixDef.restitution;
        fixtureDef.density = fixDef.density;
        fixtureDef.isSensor = fixDef.isSensor;
        
        for (int i = 0; i < [triangulatedPoints count]; i+=3)
        {
            Vector2dVector vertsTemp;
            vertsTemp.push_back([self b2VecFromCGPoint:[[triangulatedPoints objectAtIndex:i] CGPointValue]]);
            vertsTemp.push_back([self b2VecFromCGPoint:[[triangulatedPoints objectAtIndex:i+1] CGPointValue]]);
            vertsTemp.push_back([self b2VecFromCGPoint:[[triangulatedPoints objectAtIndex:i+2] CGPointValue]]);
            float area = 0;
            ComputeCentroid(vertsTemp, area);
            if (area<=0)
            {
                NSLog(@"Failure area %f was less than or equal to 0", area);
                continue;
            }
            
            b2Vec2 verts[] = {
                [self b2VecFromCGPoint:[[triangulatedPoints objectAtIndex:i] CGPointValue]],
                [self b2VecFromCGPoint:[[triangulatedPoints objectAtIndex:i+1] CGPointValue]],
                [self b2VecFromCGPoint:[[triangulatedPoints objectAtIndex:i+2] CGPointValue]]
            };
            
            b2PolygonShape shape;
            shape.Set(verts, 3);
            fixtureDef.shape = &shape;
            aBody->CreateFixture(&fixtureDef);
        }
    }
    [triangulator release];
    triangulator = nil;
}

-(void)polygonatePoints:(NSString*)pointsString ontoBody:(b2Body*)aBody withFixtureDef:(b2FixtureDef)fixDef offset:(CGSize)offset flipY:(BOOL)flipY forcePolygonation:(BOOL)forced
{
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @", "];
    float fX, fY;
    int n;
    int i, k;
    int Ymult = flipY?-1:1;
    TPPLPoly inputPoly;
    
    NSArray *pointsArray;
    
    if ([pointsString length])
    {
        pointsArray = [pointsString componentsSeparatedByCharactersInSet:characterSet];
        n = pointsArray.count;
        inputPoly.Init((long)(n/2.0f));
        
        // build polygon verticies;
        for (i = 0, k = 0; i < n; ++k)
        {
            fX = [[pointsArray objectAtIndex:i] floatValue]-offset.width;
            ++i;
            fY = Ymult*[[pointsArray objectAtIndex:i] floatValue]-offset.height;
            ++i;
            
            TPPLPoint point;
            point.x = fX/pixelsToMeterRatio();
            point.y = fY/pixelsToMeterRatio();
            inputPoly[k] = point;
        }
        inputPoly.SetOrientation(TPPL_CCW);
        
        if (inputPoly.GetNumPoints() <= 8 && !forced)
        {
            [self createPolygon:inputPoly withFixtureDef:fixDef body:aBody];
            return;
        }
        
        list<TPPLPoly> *parts = new list<TPPLPoly>;
        TPPLPartition partition;
        b2Vec2 origin = [self centerForPoly:inputPoly];
        inputPoly = [self polygon:inputPoly SizedByFactor:polyFactor];
        partition.ConvexPartition_OPT(&inputPoly, parts);
        
        for (list<TPPLPoly>::iterator it = parts->begin(); it!=parts->end(); it++)
        {
            TPPLPoly currentPoly = *it;
            int numPoints = currentPoly.GetNumPoints();
            if (numPoints <= 8)
            {
                currentPoly = [self polygon:currentPoly SizedByFactor:(1.0f/polyFactor)];
                currentPoly = [self move:currentPoly Towards:origin withFactor:(1.0f/polyFactor)];
                [self createPolygon:currentPoly withFixtureDef:fixDef body:aBody];
            }else
            {
                list<TPPLPoly> *triangles = new list<TPPLPoly>;
                partition.Triangulate_OPT(&currentPoly, triangles);
                for (list<TPPLPoly>::iterator it = triangles->begin(); it!=triangles->end(); it++)
                {
                    TPPLPoly currentTriangle = *it;
                    currentTriangle = [self polygon:currentTriangle SizedByFactor:(1.0f/polyFactor)];
                    currentTriangle = [self move:currentTriangle Towards:origin withFactor:(1.0f/polyFactor)];
                    [self createPolygon:currentTriangle withFixtureDef:fixDef body:aBody];
                }
                delete triangles;
            }
        }

        delete parts;
    }
}

-(float)areaOfPoly:(TPPLPoly)polyIn
{
    Vector2dVector vs;
    int k = 0;
    while (k<polyIn.GetNumPoints())
    {
        vs.push_back(b2Vec2(polyIn.GetPoint(k).x, polyIn.GetPoint(k).y));
        k++;
    }
    float area = 0;
    ComputeCentroid(vs, area);
    return area;
}

-(void)createPolygon:(TPPLPoly)polyIn withFixtureDef:(b2FixtureDef)fixDef body:(b2Body*)inBody
{
    if ([self areaOfPoly:polyIn] <= 0){return;}
    
    b2Vec2 *vertArray = new b2Vec2[polyIn.GetNumPoints()];
    int k = 0;
    while (k<polyIn.GetNumPoints())
    {
        vertArray[k] = b2Vec2(polyIn.GetPoint(k).x, polyIn.GetPoint(k).y);
        k++;
    }
    
    b2PolygonShape shape;
    shape.Set(vertArray, polyIn.GetNumPoints());
    fixDef.shape = &shape;
    inBody->CreateFixture(&fixDef);
    delete[] vertArray;
}

-(TPPLPoly)polygon:(TPPLPoly)polyIn SizedByFactor:(float)factor
{
    TPPLPoly output;
    output.Init(polyIn.GetNumPoints());
    
    b2Vec2 center = [self centerForPoly:polyIn];
    
    for(int i = 0; i < polyIn.GetNumPoints(); i++)
    {
        float distance = b2Distance(center, b2Vec2(polyIn.GetPoint(i).x, polyIn.GetPoint(i).y)) * factor;
        float rotation = [self pointPairToBearingDegrees:ccp(center.x, center.y) secondPoint:ccp(polyIn.GetPoint(i).x, polyIn.GetPoint(i).y)];
        CGPoint rotatedPoint = ccpRotateByAngle(ccp(center.x+distance, center.y), ccp(center.x, center.y), CC_DEGREES_TO_RADIANS(rotation));
        TPPLPoint point;
        point.x = rotatedPoint.x;
        point.y = rotatedPoint.y;
        output[i] = point;
    }
    return output;
}

-(b2Vec2)centerForPoly:(TPPLPoly)polyIn
{
    b2Vec2 output = b2Vec2(0,0);
    for(int i = 0; i < polyIn.GetNumPoints(); i++)
    {
        output.x += polyIn.GetPoint(i).x;
        output.y += polyIn.GetPoint(i).y;
    }
    output.x = output.x/polyIn.GetNumPoints();
    output.y = output.y/polyIn.GetNumPoints();
    return output;
}

-(b2Vec2)center:(Vector2dVector)vs
{
    b2Vec2 output = b2Vec2(0,0);
    for(int i = 0; i < vs.size(); i++)
    {
        output.x += vs[i].x;
        output.y += vs[i].y;
    }
    output.x = output.x/vs.size();
    output.y = output.y/vs.size();
    return output;
}

-(CGPoint)centerForPolyArray:(NSMutableArray*)polyIn
{
    CGPoint output = ccp(0, 0);
    for (NSValue *value in polyIn)
    {
        output = ccp(output.x + [value CGPointValue].x, output.y + [value CGPointValue].y);
    }
    return ccp(output.x/[polyIn count], output.y/[polyIn count]);
}

-(TPPLPoly)move:(TPPLPoly)polyIn Towards:(b2Vec2)center withFactor:(float)factor
{
    TPPLPoly output;
    output.Init(polyIn.GetNumPoints());
    
    b2Vec2 outputCenter = [self centerForPoly:polyIn];
    b2Vec2 distanceVector = b2Vec2(outputCenter.x-center.x, outputCenter.y-center.y);
    
    for(int i = 0; i < polyIn.GetNumPoints(); i++)
    {        
        TPPLPoint point;
        point.x = polyIn.GetPoint(i).x - distanceVector.x + (distanceVector.x*factor);
        point.y = polyIn.GetPoint(i).y - distanceVector.y + (distanceVector.y*factor);
        output[i] = point;
    }
    return output;
}

-(b2Vec2)b2VecFromCGPoint:(CGPoint)point
{
    return b2Vec2(point.x, point.y);
}

-(CGPoint)cgpointFromB2Vec2:(b2Vec2)point
{
    return ccp(point.x, point.y);
}

-(BOOL)probabilityWithPercent:(int)percent
{
    int random = arc4random_uniform(100);
    return random < percent;
}

-(void)handleContact:(b2Contact*)contact withImpulse:(const b2ContactImpulse*)impulse otherFixture:(b2Fixture*)otherFixture
{
    //Handle in subclass
}

-(double)pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    double bearingRadians = atan2(originPoint.y, originPoint.x); // get bearing in radians
    double bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
    bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return bearingDegrees;
}

-(void)handleContact:(b2Contact *)contact withOldManifold:(const b2Manifold *)oldManifold otherFixture:(b2Fixture *)otherFixture
{
    //If we need the other sprite from the fixture make sure to add another setup like below but for fixtures
    Box2DSprite *otherSprite = (Box2DSprite*)otherFixture->GetBody()->GetUserData();
    if (!otherSprite) {return;}
    
    if ([[otherSprite class] isSubclassOfClass:[Box2DSprite class]])
    {
        if ([otherSprite gameObjectType] == kSplashZoneType)
        {
            if ((fabs(body->GetLinearVelocity().y)  > 5 || fabs(body->GetLinearVelocity().x)  > 10) && [self probabilityWithPercent:DUST_PROBABILITY])
            {
                b2WorldManifold mani;
                contact->GetWorldManifold(&mani);
                
                b2Vec2 worldPoint = mani.points[0];
                CGPoint position = ccp(worldPoint.x*pixelsToMeterRatio(), worldPoint.y*pixelsToMeterRatio());
                
                for (NSString *emitterName in [(SplashZone*)otherSprite splashEmitters])
                {
                    emitterName = [NSString stringWithFormat:@"%@%@", emitterName, @".plist"];
                    
                    CCParticleSystemQuad *splashEmitter = [[EmitterManager sharedManager] getSpashEmitter:emitterName];
                    if (!splashEmitter) {continue;}
                    [[splashEmitter texture] setAliasTexParameters];
                    [splashEmitter setAutoRemoveOnFinish:YES];
                    [splashEmitter setPositionType:kCCPositionTypeGrouped];
                    [splashEmitter setPosition:position];
                    [[self parent] addChild:splashEmitter z:[self zOrder]+1];
                    [splashEmitter resetSystem];
                    if (fabs(body->GetLinearVelocity().y)  > 8)
                    {
                        [self playSoundEffect:@"WATER.mp3" withProbability:0.6];
                    }
                }
            }
        }
    }
}

@end
