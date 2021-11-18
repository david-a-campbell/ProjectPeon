//
//  ForceArea.m
//  rover
//
//  Created by David Campbell on 6/15/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "ForceArea.h"
#import "Box2DHelpers.h"
#import "Wheel.h"
#import "CartPart.h"
#import "UIImage+Extras.h"
#import "PRFilledPolygon.h"
#import "PlayerCart.h"
#import "Bar.h"

@implementation ForceArea
-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld objectGroup:(CCTMXObjectGroup*)spriteObjects andParent:(CCNode *)parent
{
    if ((self = [super init]))
    {
        allowFullScreenEmitter = YES;
        emitterFollowsScreen = [[dict valueForKey:@"EmitterFollowsScreen"] intValue];
        forceID = [[dict valueForKey:@"ForceID"] intValue];
        [self setCharacterState:kStateForceStopped];
        world = theWorld;
        gameObjectType = kForceAreaType;
        [self setupForceWithDict:dict];
        [self setupBodyWithDict:dict];
        [self setupFixtureWithDict:dict andParent:parent];
        [self setupPropertiesWithDict:dict];
        [self setupEmitters:spriteObjects withParent:parent];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginForceCycle) name:NOTIFICATION_BEGIN_GAMEPLAY object:nil];
        liquidDensity = 6500;
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

-(void)setupPropertiesWithDict:(id)dict
{
    time = [[dict valueForKey:@"Time"] floatValue];
    stopTime = [[dict valueForKey:@"StopTime"] floatValue];
}

-(void)setupEmitters:(CCTMXObjectGroup*)spriteObjects withParent:(CCNode*)parent
{
    [self setEmitterArray:[NSMutableArray array]];
    NSMutableArray *objectArray = [spriteObjects objects];
    for (id object in objectArray)
    {
        if ([[object valueForKey:@"type"] isEqualToString:@"Emitter"])
        {
            if ([[object valueForKey:@"ForceID"] intValue] != forceID)
            {
                continue;
            }
            
            NSString* emitterType = [object valueForKey:@"EmitterType"];
            if (![emitterType length]){continue;}
            emitterType = [NSString stringWithFormat:@"%@%@", emitterType, @".plist"];
            
            float x = [[object valueForKey:@"x"] floatValue];
            float y = [[object valueForKey:@"y"] floatValue];
            
            CCParticleSystemQuad *emitter = [CCParticleSystemQuad particleWithFile:emitterType];
            [[emitter texture] setAliasTexParameters];
            [emitter setAutoRemoveOnFinish:NO];
            [emitter setPositionType:kCCPositionTypeRelative];
            [emitter setPosition:ccp(x, y)];
            
            [parent addChild:emitter z:GroundZ-1];
            [_emitterArray addObject:emitter];
            [emitter stopSystem];
        }
    }
}

-(void)setupForceWithDict:(id)dict
{
    forceVector = ccp(0, 0);
    forceAmount = 0;
    isBuoyancyArea = NO;
    if ([dict valueForKey:ForceX]!=nil)
        forceVector.x = [[dict valueForKey:ForceX] floatValue];
    if ([dict valueForKey:ForceY]!=nil)
        forceVector.y = [[dict valueForKey:ForceY] floatValue];
    if ([dict valueForKey:ForceAmount] != nil)
        forceAmount = [[dict valueForKey:ForceAmount] floatValue]*2;
    if ([dict valueForKey:IsLiquid] != nil)
        isBuoyancyArea = [[dict valueForKey:IsLiquid] intValue];
}

-(void)setupBodyWithDict:(id)dict
{
    float x = [[dict valueForKey:@"x"] floatValue];
    float y = [[dict valueForKey:@"y"] floatValue];
    [self setPosition:ccp(x, y)];
    
    b2BodyDef forceBodyDef;
    forceBodyDef.type = b2_staticBody;
    forceBodyDef.position.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    body = world->CreateBody(&forceBodyDef);
    body->SetUserData(self);
}

-(void)setupFixtureWithDict:(id)dict andParent:(CCNode*)parent
{
    b2FixtureDef fixtureDef;
    fixtureDef.filter.maskBits = kDontCollideWithGround;
    fixtureDef.isSensor = true;
    NSString *pointsString = [dict valueForKey:@"polygonPoints"];
    NSMutableArray *polygonPoints = [self polygonPointsFromString:pointsString offset:CGSizeMake(0, 0) flipY:YES];
    [self polygonatePoints:pointsString ontoBody:body withFixtureDef:fixtureDef offset:CGSizeMake(0, 0) flipY:YES forcePolygonation:!isBuoyancyArea];
    
    if (isBuoyancyArea)
    {
        NSAssert([polygonPoints count]<=8 && [polygonPoints count]>0, @"must have less than 8 verts for BuoyancyArea");
    }
    
    fixtureA = body->GetFixtureList();
    fixtureA->SetUserData(self);
    
    if ([[dict valueForKey:@"Texture1"] length])
    {
        PRFilledPolygon *filledPolygon = [self getTexture:[dict valueForKey:@"Texture1"] withPoints:polygonPoints];
        [filledPolygon setPosition:[self position]];
        [parent addChild:filledPolygon z:GroundZ-1];
    }
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    if (emitterFollowsScreen)
    {
        [self updateEmitterPositions];
    }
    
    if (isBuoyancyArea)
    {
        [self performBuoyancyArea];
    }else
    {
        if ([self characterState] != kStateForceStopped && [self characterState] != kStateForceWaiting)
        {
            [self performForceArea]; 
        }
    }
}

-(void)updateEmitterPositions
{
    CGPoint parentPos = [[self parent] position];
    float scale = [[self parent] scale];
    CGSize winSize = CGSizeMake([CCDirector sharedDirector].winSize.width/scale, [CCDirector sharedDirector].winSize.height/scale);
    
    for (CCParticleSystemQuad *emitter in _emitterArray)
    {
        [emitter setPosition:ccp(-parentPos.x/scale + winSize.width/2.0f, -parentPos.y/scale + winSize.height/2.0f)];
    }
}

-(void)changeState:(CharacterStates)newState
{
    if (characterState == newState) {return;}

    [self setCharacterState:newState];
    if (newState == kStateForceStopped)
    {
        [self stopAllActions];
    }
    if (newState == kStateForceWaiting)
    {
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:stopTime], [CCCallFunc actionWithTarget:self selector:@selector(resumeForce)],nil]];
    }
    if (newState == kStateForceApplied)
    {
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:time], [CCCallFunc actionWithTarget:self selector:@selector(beginForceCycle)],nil]];

            if (!emitterFollowsScreen || allowFullScreenEmitter)
            {
                [_emitterArray makeObjectsPerformSelector:@selector(resetSystem)];
            }
    }
    if (newState == kStateForceWaiting || newState == kStateForceStopped)
    {
        [_emitterArray makeObjectsPerformSelector:@selector(stopSystem)];
    }
}

-(void)resetForceCycle
{
    [self changeState:kStateForceStopped];
}

-(void)resumeForce
{
    [self changeState:kStateForceApplied];
}

-(void)beginForceCycle
{
    [self changeState:kStateForceWaiting];
}

-(void)performForceArea
{
    allowFullScreenEmitter = NO;
    b2Vec2 force = b2Vec2(forceAmount * forceVector.x, forceAmount * forceVector.y);
    VectorB2Body forcedBodies;
    b2ContactEdge* edge = body->GetContactList();
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching())
        {
            b2Fixture* fixtureB = contact->GetFixtureB();
            b2Body *bodyB = fixtureB->GetBody();
            Box2DSprite *fixtureBSprite = (Box2DSprite*)fixtureB->GetUserData();
            Box2DSprite *bodyBSprite = (Box2DSprite*)bodyB->GetUserData();
            if (fixtureB->IsSensor() || [self vector:forcedBodies containsBody:bodyB])
            {
                edge = edge->next;
                continue;
            }
            
            if (fixtureBSprite != nil && fixtureBSprite != self)
            {
                b2Vec2 finalForce = force;
                if (bodyBSprite.gameObjectType == kThingyBasic)
                {
                    finalForce = b2Vec2(force.x * 0.02f, force.y * 0.02f);
                }
                
                bodyB->ApplyForceToCenter(finalForce);
                forcedBodies.push_back(bodyB);
                
                if (bodyBSprite.gameObjectType == kPlayerCartType)
                {
                    PlayerCart *cart = (PlayerCart*)bodyBSprite;
                    if ([cart body:bodyB isWithinRadius:1024])
                    {
                        allowFullScreenEmitter = YES;
                    }
                }
            }
        }
        edge = edge->next;
    }
    
    if (emitterFollowsScreen && !allowFullScreenEmitter)
    {
        [_emitterArray makeObjectsPerformSelector:@selector(stopSystem)];
    }
    
    if (emitterFollowsScreen && allowFullScreenEmitter && characterState == kStateForceApplied)
    {
        for (CCParticleSystemQuad *emitter in _emitterArray)
        {
            if (![emitter active])
            {
                [emitter resetSystem];
            }
        }
    }
}

-(BOOL)vector:(VectorB2Body)inVec containsBody:(b2Body*)inBody
{
    for (VectorB2Body::iterator it = inVec.begin(); it != inVec.end(); ++it)
    {
        b2Body *aBody = *it;
        if (aBody == inBody)
        {
            return YES;
        }
    }
    return NO;
}

-(void)performBuoyancyArea
{
    VectorB2Body forcedBodies;
    b2Vec2 force = b2Vec2(forceAmount * forceVector.x, forceAmount * forceVector.y);
    b2ContactEdge* edge = body->GetContactList();
    
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching())
        {
            b2Fixture* fixtureB = contact->GetFixtureB();
            b2Body *bodyB = fixtureB->GetBody();
            Box2DSprite *spriteB = (Box2DSprite*)fixtureB->GetUserData();
            
            if (fixtureB->IsSensor() || [self vector:forcedBodies containsBody:bodyB])
            {
                edge = edge->next;
                continue;
            }
            
            if (spriteB != nil)
            {
                b2Fixture *fixtureObj = fixtureB;
                if ([[spriteB class] isSubclassOfClass:[Wheel class]])
                {
                    Wheel *aWheel = (Wheel*)spriteB;
                    fixtureObj = [aWheel buoyancyFixture];
                }
                
                Vector2dVector intersectionPoints;
                if (findIntersectionOfFixtures(fixtureA, fixtureObj, intersectionPoints))
                {
                    //find centroid
                    float area = 0;
                    b2Vec2 centroid = ComputeCentroid( intersectionPoints, area);
                    
                    //apply buoyancy force (fixtureA is the fluid)
                    float displacedMass = area * liquidDensity;
                    b2Vec2 buoyancyForce = displacedMass * force;

                    if ([spriteB gameObjectType] == kThingyBasic)
                    {
                        bodyB->ApplyForceToCenter(buoyancyForce);
                    }else
                    {
                        bodyB->ApplyForce(buoyancyForce, centroid);
                    }
                    
                    bodyB->SetAngularDamping(0.3f);
                    bodyB->SetLinearDamping(0.4f);
                    forcedBodies.push_back(bodyB);
                }
            }
        }
        edge = edge->next;
    }
}

@end
