//
//  Booster.m
//  rover
//
//  Created by David Campbell on 5/26/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Booster.h"
#import "PlayerCart.h"
#import "Constants.h"
#import "Box2DHelpers.h"
#import "Ground.h"
#import "BreakableGround.h"
#import "BoosterRayCastCalllback.h"
#import "EmitterManager.h"
#import "SplashZone.h"

#define BOOST 100000.0f
#define BOOST_UPGRADE 150000.0f

@implementation Booster


- (id)initWithStart:(CGPoint)touchStartLocation andEnd: (CGPoint)touchEndLocation andCart:(PlayerCart *)theCart andLayer:(CCLayer *)lyr andType:(GameObjectType)type
{
    if ((self = [super initWithStart:touchStartLocation andEnd:touchEndLocation andCart:theCart]))
    {
        gameObjectType = type;
        if (type == kBoosterPartType)
        {
            boost = BOOST;
            boostFollow = 25;
        }else if(type == kBooster50PartType)
        {
            boost = BOOST_UPGRADE;
            density = density*0.5;
            boostFollow = 50;
        }
        layer = lyr;
        [self setupFixture];
        [self setupImage];
        [self scheduleUpdate];
        shouldFireBooster = NO;
        ranOutOfFuel = NO;
    }
    return self;
}

-(void)setRotation:(float)rotation
{
    [blastEmitter setRotation:rotation+rotationOffset];
    [super setRotation:rotation+rotationOffset];
}

-(void)setPosition:(CGPoint)position
{
    b2Vec2 center = body->GetWorldPoint([self positionOffset]);
    CGPoint pos = ccp(center.x*pixelsToMeterRatio(), center.y*pixelsToMeterRatio());
    CGPoint boostFollowPoint = ccp(pos.x - boostFollow, pos.y-1);
    boostFollowPoint = ccpRotateByAngle(boostFollowPoint, pos, CC_DEGREES_TO_RADIANS(-[self rotation]));
    [blastEmitter setPosition:boostFollowPoint];
    [super setPosition:pos];
}

-(void)setupImage
{
    if (gameObjectType == kBoosterPartType)
    {
        [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"booster.png"]];
        blastEmitter = [CCParticleSystemQuad particleWithFile:@"RocketBlast.plist"];
    }else if (gameObjectType == kBooster50PartType)
    {
        CCAnimation *animation = [self loadPlistForAnimationWithName:@"pulse" andClassName:@"boosterUpgrade"];
        id repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:animation]];
        [self runAction:repeat];
        blastEmitter = [CCParticleSystemQuad particleWithFile:@"RocketBlastUpgrade.plist"];
    }

    rotationOffset = -[self pointPairToBearingDegrees:start secondPoint:end];
    [self setScale:1];
    [[blastEmitter texture] setAliasTexParameters];
    [blastEmitter setPositionType:kCCPositionTypeGrouped];
    [layer addChild:blastEmitter z:[self zOrder]-1];
    [blastEmitter stopSystem];
}

//used to rotate the points
-(b2Vec2)ConfigurePoint:(CGPoint)point withOffset:(b2Vec2)offset
{
    CGPoint temp;
    float mainAngle = [self pointPairToBearingDegrees:start secondPoint:end];
    CGPoint pivot;
    if (gameObjectType == kBoosterPartType)
    {
        pivot = ccp(35.5f, 22.25f);
    }else if (gameObjectType == kBooster50PartType)
    {
        pivot = ccp(51.0f, 34.0f);
    }
    temp = ccpRotateByAngle(point, pivot, CC_DEGREES_TO_RADIANS(mainAngle));
    temp = ccp((temp.x -pivot.x)/pixelsToMeterRatio(), (temp.y -pivot.y)/pixelsToMeterRatio());
    return b2Vec2(temp.x+offset.x, temp.y+offset.y);
}

-(void)setupFixture
{
    b2PolygonShape *shape = [self createShape];
    processBody(self, shape);
    delete shape;
}

-(b2PolygonShape*)createShape
{
    b2Vec2 position = b2Vec2(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
    return [self createShapeForCenter:position];
}

-(b2PolygonShape*)createShapeForCenter:(b2Vec2)center
{
    b2Vec2 position = b2Vec2(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
    [self setPositionOffset:b2Vec2(position.x-center.x, position.y-center.y)];
    
    b2PolygonShape *shape = new b2PolygonShape();
    
    if (gameObjectType == kBoosterPartType)
    {
        [self vertsForBooster:shape];
    }else if (gameObjectType == kBooster50PartType)
    {
        [self vertsForBooster50:shape];
    }
    
    return shape;
}

-(void)vertsForBooster:(b2PolygonShape*)shape
{
    b2Vec2 verts[] = {
        b2Vec2([self ConfigurePoint:ccp(0.0f, 38.5f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(8.5f, 44.5f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(30.0f, 44.5f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(69.5f, 40.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(69.5f, 4.5f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(30.0f, 0.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(8.5f, 0.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(0.0f, 6.0f) withOffset:[self positionOffset]])
    };
    shape->Set(verts, 8);
}

-(void)vertsForBooster50:(b2PolygonShape*)shape
{
    b2Vec2 verts[] = {
        b2Vec2([self ConfigurePoint:ccp(0.0f, 9.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(0.0f, 59.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(34.5f, 68.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(62.5f, 66.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(102.0f, 55.5f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(102.0f, 12.5f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(62.5f, 2.0f) withOffset:[self positionOffset]]),
        b2Vec2([self ConfigurePoint:ccp(34.5f, 0.0f) withOffset:[self positionOffset]])
    };
    shape->Set(verts, 8);
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

-(void)resetPart;
{
    [super resetPart];
    [self setupFixture];
    shouldFireBooster = NO;
}

-(BOOL)shouldRemoveFromTouchArray
{
    return isReadyForRemoval;
}

-(void)fireBooster
{
    if (!shouldFireBooster){return;}
    if (![cart hasFuel])
    {
        ranOutOfFuel = YES;
        [blastEmitter stopSystem];
        return;
    }else if (ranOutOfFuel)
    {
        [blastEmitter resetSystem];
        ranOutOfFuel = NO;
    }
    
    [cart drainFuelAmount:2];
    CGPoint forceCCP = ccp(boost,0);
    forceCCP = ccpRotateByAngle(forceCCP, ccp(0,0), CC_DEGREES_TO_RADIANS(-[self rotation]));
    b2Vec2 forceAmount(forceCCP.x, forceCCP.y);
    body->ApplyLinearImpulse(forceAmount, body->GetWorldPoint([self positionOffset]));
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    [self fireBooster];
}

-(void)buttonPressBegan
{
    shouldFireBooster = YES;
    if ([cart hasFuel])
    {
        [blastEmitter resetSystem];
    }
}

-(void)buttonPressEnded
{
    shouldFireBooster = NO;
    [blastEmitter stopSystem];
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

-(void)update:(ccTime)delta
{
    if (!shouldFireBooster || ![cart hasFuel]){return;}
    
    BoosterRayCastcallback callback;
    b2Vec2 origin = b2Vec2(_position.x/pixelsToMeterRatio(), _position.y/pixelsToMeterRatio());
    b2Vec2 final = b2Vec2(origin.x - 700/pixelsToMeterRatio(),origin.y);
    
    CGPoint ccpPos = ccpRotateByAngle([self cgpointFromB2Vec2:final], [self cgpointFromB2Vec2:origin], CC_DEGREES_TO_RADIANS(-[self rotation]));
    world->RayCast(&callback, origin, [self b2VecFromCGPoint:ccpPos]);
    
    if (!callback.points.size()){return;}
    
    b2Vec2 closest = callback.points[0];
    int index = 0;
    int indexToUse = 0;
    for (Vector2dVector::iterator it = callback.points.begin(); it != callback.points.end(); ++it)
    {
        b2Vec2 nextPoint = *it;
        if (b2Distance(origin, closest) > b2Distance(origin, nextPoint))
        {
            closest = nextPoint;
            indexToUse = index;
        }
        index++;
    }
    [self createDustForGround:callback.fixtures[indexToUse] point:closest];
}

-(void)createDustForGround:(b2Fixture *)groundFix point:(b2Vec2)point
{
    Box2DSprite *otherSprite = (Box2DSprite*)groundFix->GetBody()->GetUserData();
    
    if ([self probabilityWithPercent:DUST_PROBABILITY])
    {
        CGPoint position = ccp(point.x*pixelsToMeterRatio(), point.y*pixelsToMeterRatio());
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

-(void)dealloc
{
    [super dealloc];
}

@end
