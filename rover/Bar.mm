//
//  Bar.m
//  rover
//
//  Created by David Campbell on 3/9/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Bar.h"
#import "PlayerCart.h"
#import "Constants.h"
#import "Box2DHelpers.h"
#import "Ground.h"
#import "BreakableGround.h"
#import "EmitterManager.h"
#import "SplashZone.h"

@implementation Bar

- (id)initWithStart:(CGPoint)touchStartLocation andEnd: (CGPoint)touchEndLocation andCart:(PlayerCart *)theCart
{
    if ((self = [super initWithStart:touchStartLocation andEnd:touchEndLocation andCart:theCart]))
    {
        gameObjectType = kBarPartType;
        density = 16000;
        [self setupFixture];
        [self createSensor];
        [self setupImage];
    }
    return self;
}

-(void)setRotation:(float)rotation
{
    [super setRotation:(rotation)+rotationOffset];
}

-(void)setPosition:(CGPoint)position
{
    b2Vec2 center = body->GetWorldPoint([self positionOffset]);
    [super setPosition:ccp(center.x*pixelsToMeterRatio(), center.y*pixelsToMeterRatio())];
}

-(void)setupImage
{
    [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"bar.png"]];
    float length = ccpDistance(start, end);
    [self setScaleX:length/[self boundingBox].size.width];
    [self setScaleY:1];
    rotationOffset = -[self pointPairToBearingDegrees:start secondPoint:end];
}

-(void)setupFixture
{    
    b2PolygonShape *shape = [self createShape];
    processBody(self, shape);
    delete shape;
}

-(b2PolygonShape*)createShape
{
    CGPoint mid = ccpMidpoint(start, end);
    b2Vec2 position = b2Vec2(mid.x/pixelsToMeterRatio(), mid.y/pixelsToMeterRatio());
    return [self createShapeForCenter:position];
}

-(b2PolygonShape*)createShapeForCenter:(b2Vec2)center
{
    CGPoint mid = ccpMidpoint(start, end);
    b2Vec2 position = b2Vec2(mid.x/pixelsToMeterRatio(), mid.y/pixelsToMeterRatio());
    [self setPositionOffset:b2Vec2(position.x-center.x, position.y-center.y)];
    
    b2PolygonShape *shape = new b2PolygonShape();
    float mainAngle = [self pointPairToBearingDegrees:start secondPoint:end];
    float distance = ccpDistance(start, end);
    shape->SetAsBox((1.5*4.375)/pixelsToMeterRatio(), (distance/2.0)/pixelsToMeterRatio(), [self positionOffset], CC_DEGREES_TO_RADIANS(mainAngle + 90));
    return shape;
}

-(b2FixtureDef)createFixtureDef
{
    b2FixtureDef fixtureDef;
    fixtureDef.friction = friction;
    fixtureDef.restitution = restitution;
    fixtureDef.density = density;
    fixtureDef.filter.categoryBits = categoryBits;
    fixtureDef.filter.maskBits = maskBits;
    fixtureDef.filter.groupIndex = groupIndex;
    return fixtureDef;
}

-(void)createSensor
{
    b2FixtureDef fixtureDef;
    fixtureDef.filter.maskBits = kCollideWithNone;
    fixtureDef.isSensor = true;
    b2PolygonShape shape;
    float mainAngle = [self pointPairToBearingDegrees:start secondPoint:end];
    float distance = ccpDistance(start, end);
    shape.SetAsBox((4.375*3)/pixelsToMeterRatio(), (distance/2.0)/pixelsToMeterRatio(), [self positionOffset], CC_DEGREES_TO_RADIANS(mainAngle + 90));
    fixtureDef.shape = &shape;

    _sensorFixture = body->CreateFixture(&fixtureDef);
    _sensorFixture->SetUserData(self);
}

-(void)resetPart;
{
    [super resetPart];
    [self setupFixture];
    [self createSensor];
}

-(void)destroyExtraFixtures
{
    if (_sensorFixture)
    {
        body->DestroyFixture(_sensorFixture);
        _sensorFixture->SetUserData(NULL);
        _sensorFixture = nil;
    }
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

@end
