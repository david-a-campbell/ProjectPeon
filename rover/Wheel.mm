//
//  Wheel.m
//  rover
//
//  Created by David Campbell on 3/10/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Wheel.h"
#import "PlayerCart.h"
#import "Box2DHelpers.h"
#import "SimpleQueryCallback.h"
#import "Bar.h"
#import "Motor.h"
#import "Ground.h"
#import "BreakableGround.h"
#import "EmitterManager.h"
#import "SplashZone.h"

@implementation Wheel

- (id)initWithStart:(CGPoint)touchStartLocation andEnd: (CGPoint)touchEndLocation andCart:(PlayerCart *)theCart andType:(GameObjectType)type
{
    if ((self = [super initWithStart:touchStartLocation andEnd:touchEndLocation andCart:theCart]))
    {
        restitution = [self restitution];
        density = 2500;
        gameObjectType = type;
        [self setupFixture];
        [self createBuoyancyFixture];
        [self setupImage];
    }
    return self;
}

-(float)restitution
{
    return restitution;
}

-(float)friction
{
    return 2;
}

-(void)dealloc
{
    [pivotIndicator release];
    pivotIndicator = nil;
    [super dealloc];
}

-(void)setRotation:(float)rotation
{
    [super setRotation:rotation+rotationOffset];
}

-(void)setPosition:(CGPoint)position
{
    b2Vec2 center = body->GetWorldPoint([self positionOffset]);
    [super setPosition:ccp(center.x*pixelsToMeterRatio(), center.y*pixelsToMeterRatio())];
}

-(void)setupImage
{
    [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"circle.png"]];
    [self addPivotIndicator];
    [self setPosition:start];
    float diameter = ccpDistance(start, end)*2.0f;
    [self setScale:diameter/[self boundingBox].size.height];
    rotationOffset = -[self pointPairToBearingDegrees:start secondPoint:end];
}

-(void)addPivotIndicator
{
    pivotIndicator = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"pivot.png"]];
    [pivotIndicator setPosition:ccp([self boundingBox].size.height/2,[self boundingBox].size.width/2)];
    [self addChild:pivotIndicator];
    [self showPivotIndicator];
}

-(void)showPivotIndicator
{
    if (doesSwivel) {
        [pivotIndicator setOpacity:255];
    }else {
        [pivotIndicator setOpacity:0];
    }
}

-(void)hidePivotIndicator
{
    [pivotIndicator setOpacity:0];
}

-(void)setupFixture
{    
    fixture = nil;
    doesSwivel = NO;
    categoryBits = kLayer1Cat;
    
    _swivelBody = [self getSwivelBody];
    
    if (_swivelBody)
    {
        doesSwivel = YES;
        categoryBits = kLayer2Cat;
        [self setIsInForeground:YES];
    }
    
    if (_swivelBody || [self gameObjectType] == kMotorPartType || [self gameObjectType] == kMotor50PartType)
    {
        b2BodyDef bd;
        bd.position = b2Vec2(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
        bd.type = b2_staticBody;
        body = world->CreateBody(&bd);
        body->SetUserData(cart);
        
        b2CircleShape *shape = [self createShape];
        b2FixtureDef fixtureDef = [self createFixtureDef];
        fixtureDef.shape = shape;
        fixture = body->CreateFixture(&fixtureDef);
        fixture->SetUserData(self);
        delete shape;
    }else
    {
        b2CircleShape *shape = [self createShape];
        processBody(self, shape);
        delete shape;
    }

    
    if (_swivelBody)
    {
        [self setupWheelJointWithBody:_swivelBody];
    }
}

-(void)createBuoyancyFixture
{
    float radius = ccpDistance(start, end)/pixelsToMeterRatio();
    
    b2PolygonShape polygon;
    b2Vec2 pivot =[self positionOffset];
    b2Vec2 endPoint = b2Vec2(0+[self positionOffset].x, radius+[self positionOffset].y);
    
    b2Vec2 verts[] = {
        endPoint,
        [self point:endPoint rotatedByAngle:45 aroundPivot:pivot],
        [self point:endPoint rotatedByAngle:90 aroundPivot:pivot],
        [self point:endPoint rotatedByAngle:135 aroundPivot:pivot],
        [self point:endPoint rotatedByAngle:180 aroundPivot:pivot],
        [self point:endPoint rotatedByAngle:225 aroundPivot:pivot],
        [self point:endPoint rotatedByAngle:270 aroundPivot:pivot],
        [self point:endPoint rotatedByAngle:315 aroundPivot:pivot]
    };
    
    polygon.Set(verts, 8);
    b2FixtureDef fixtureDef;
    fixtureDef.isSensor = YES;
    fixtureDef.shape = &polygon;
    
    _buoyancyFixture = body->CreateFixture(&fixtureDef);
    _buoyancyFixture->SetUserData(self);
}

-(b2Vec2)point:(b2Vec2)point rotatedByAngle:(float)angle aroundPivot:(b2Vec2)pivot
{
    CGPoint pointCG = ccp(point.x, point.y);
    CGPoint pivotCG = ccp(pivot.x, pivot.y);
    CGPoint output = ccpRotateByAngle(pointCG, pivotCG, CC_DEGREES_TO_RADIANS(angle));
    return b2Vec2(output.x, output.y);
}

-(b2Body*)getSwivelBody
{
    //Find Swivel backing
    b2Vec2 b2Start(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
    b2AABB aabb;
    b2Vec2 delta = b2Vec2(1.0/pixelsToMeterRatio(), 1.0/pixelsToMeterRatio());
    aabb.lowerBound = b2Start - delta;
    aabb.upperBound = b2Start + delta;
    SimpleQueryCallback callback(b2Start, fixture);
    world->QueryAABB(&callback, aabb);
    if (callback.fixtureFound != nil) 
    {
        GameObject *tempPart = (GameObject*)callback.fixtureFound->GetBody()->GetUserData();
        CartPart* foundPart = (CartPart*)callback.fixtureFound->GetUserData();
        if (tempPart.gameObjectType != kPlayerCartType || foundPart.isInForeground || foundPart.gameObjectType == kMotorPartType || foundPart.gameObjectType == kMotor50PartType)
        {
            return nil;
        }
        
        if (foundPart.gameObjectType == kBarPartType)
        {
            b2Vec2 testPoint(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
            if (!callback.fixtureFound->TestPoint(testPoint))
            {
                [self adjustStartPointForBar:(Bar*)foundPart];
            }
        }
        return callback.fixtureFound->GetBody();
    }
    return nil;
}

-(void)adjustStartPointForBar:(Bar*)bar
{
    CGPoint otherEnd = ccpRotateByAngle([bar end], [bar start], CC_DEGREES_TO_RADIANS(-180));
    CGPoint pivot;
    float distanceToA = ccpDistance([bar end], start);
    float distanceToB = ccpDistance(otherEnd, start);
    
    if (distanceToA < distanceToB)
    {
        pivot = otherEnd;
    }else
    {
        pivot = [bar end];
    }
    
    float angle1 = [self pointPairToBearingDegrees:pivot secondPoint:start];
    float angle2 = [self pointPairToBearingDegrees:pivot secondPoint:[bar start]];
    
    float angleFinal = fabs(angle1-angle2) > 90 ? 360-fabs(angle1-angle2):fabs(angle1-angle2);
    angleFinal = 2.0f*angleFinal;
    
    CGPoint otherSide = ccpRotateByAngle(start, pivot, CC_DEGREES_TO_RADIANS(angleFinal));
    CGPoint adjustedStart = ccpIntersectPoint([bar end], otherEnd, start, otherSide);
    
    float adjustedDifferenceX = start.x - adjustedStart.x;
    float adjustedDifferenceY = start.y - adjustedStart.y;
    
    end = ccp(end.x-adjustedDifferenceX, end.y-adjustedDifferenceY);
    start = adjustedStart;
}

-(void)setupWheelJointWithBody:(b2Body*)foundBody
{
    _swivelBody = foundBody;
    b2RevoluteJointDef jointDef;
    jointDef.collideConnected = NO;
    jointDef.Initialize(foundBody, body, body->GetWorldPoint([self positionOffset]));
    _joint = world->CreateJoint(&jointDef);
    _joint->SetUserData(self);
}

-(b2CircleShape*)createShape
{
    b2Vec2 position = b2Vec2(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
    return [self createShapeForCenter:position];
}

-(b2CircleShape*)createShapeForCenter:(b2Vec2)center
{
    b2Vec2 position = b2Vec2(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
    [self setPositionOffset:b2Vec2(position.x-center.x, position.y-center.y)];
    
    b2CircleShape *shape = new b2CircleShape();
    float radius = ccpDistance(start, end);
    shape->m_radius = radius/pixelsToMeterRatio();
    shape->m_p = [self positionOffset];
    return shape;
}

-(b2FixtureDef)createFixtureDef
{    
    b2FixtureDef _fixtureDef;
    _fixtureDef.friction = [self friction];
    _fixtureDef.restitution = restitution;
    _fixtureDef.density = density;
    _fixtureDef.filter.categoryBits = categoryBits;
    _fixtureDef.filter.maskBits = maskBits;
    _fixtureDef.filter.groupIndex = groupIndex;
    
    return _fixtureDef;
}

-(void)highlightMe
{
    [super highlightMe];
    [pivotIndicator setColor:highlightedColor];
}

-(void)unHighlightMe
{
    [super unHighlightMe];
    [pivotIndicator setColor:originalColor];
}

-(void)reappear
{
    CCFadeTo *fade = [CCFadeTo actionWithDuration:1.5 opacity:255];
    [self runAction:[[fade copy] autorelease]];
    for (CCNode *partImage in [self children])
    {
        if (partImage != pivotIndicator)
        {
            [partImage runAction:[[fade copy] autorelease]];
        }
    }
}

-(void)resetPart;
{
    //Dont delete fixtures or bodies here (they already happened)
    [super resetPart];
    [self setupFixture];
    [self createBuoyancyFixture];
}

-(void)destroyExtraFixtures
{
    if (_joint){_joint->SetUserData(NULL);}
    if (_buoyancyFixture)
    {
        _buoyancyFixture->SetUserData(NULL);
        body->DestroyFixture(_buoyancyFixture);
    }
    _joint=nil;
    _swivelBody=nil;
    _buoyancyFixture=nil;
}

-(void)handleContact:(b2Contact *)contact withImpulse:(const b2ContactImpulse *)impulse otherFixture:(b2Fixture *)otherFixture
{    
    //If we need the other sprite from the fixture make sure to add another setup like below but for fixtures
    Box2DSprite *otherSprite = (Box2DSprite*)otherFixture->GetBody()->GetUserData();
    if (!otherSprite) {return;}
    
    if ([[otherSprite class] isSubclassOfClass:[Box2DSprite class]])
    {
        if (otherSprite.gameObjectType == kGroundType || otherSprite.gameObjectType == kBreakableGroundType)
        {
            float minVelocity = (14 * MIN_WHEEL_LENGTH/ccpDistance(start, end));
            float linearVelocity = b2Distance(b2Vec2(0,0), body->GetLinearVelocity());
            if ((fabs(body->GetAngularVelocity()) > minVelocity && fabsf(linearVelocity) < 20)
                || (fabs(body->GetAngularVelocity()) < 1 && fabsf(linearVelocity) > 8))
            {
                if ([self probabilityWithPercent:DUST_PROBABILITY])
                {                    
                    b2WorldManifold mani;
                    contact->GetWorldManifold(&mani);
                    
                    b2Vec2 worldPoint = mani.points[0];
                    CGPoint position = ccp(worldPoint.x*pixelsToMeterRatio(), worldPoint.y*pixelsToMeterRatio());
                
                    for (NSString *emitterName in [(Ground*)otherSprite dustEmitters])
                    {
                        emitterName = [NSString stringWithFormat:@"%@%@", emitterName, @".plist"];
                        
                        CCParticleSystemQuad *dustEmitter = [[EmitterManager sharedManager] getGroundEmitter:emitterName];
                        if (!dustEmitter) {continue;}
                        [[dustEmitter texture] setAliasTexParameters];
                        [dustEmitter setAutoRemoveOnFinish:YES];
                        [dustEmitter setPositionType:kCCPositionTypeGrouped];
                        [dustEmitter setPosition:position];
                        [[self parent] addChild:dustEmitter z:[self zOrder]+1];
                        [dustEmitter resetSystem];
                    }
                }
            }
        }
        
        if (otherSprite.gameObjectType == kBreakableGroundType)
        {
            [(BreakableGround*)otherSprite makeGroundBreak];
        }
    }
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    body->SetAngularDamping(0.3);
}

@end
