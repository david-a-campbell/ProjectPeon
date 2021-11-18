//
//  BreakableGround.m
//  rover
//
//  Created by David Campbell on 7/5/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "BreakableGround.h"

@implementation BreakableGround

-(id)initWithWorld:(b2World *)theWorld dict:(id)dict objectGroup:(CCTMXObjectGroup *)collisionObjects andParent:(CCNode*)parent
{
    if (self = [super initWithWorld:theWorld andDict:dict isSolid:YES])
    {
        hasBroken = NO;
        [self setGameObjectType:kBreakableGroundType];
        delay = [[dict valueForKey:@"Delay"] floatValue];
        breakID = [[dict valueForKey:@"BreakID"] intValue];
        _ignoreRocks = [[dict valueForKey:@"IgnoreRocks"] intValue];
        [self setupEmitters:collisionObjects andParent:parent];
    }
    return self;
}

-(float)density
{
    return 3000;
}

-(void)setupEmitters:(CCTMXObjectGroup*)collisionObjects andParent:(CCNode*)parent
{    
    [self setEmitterArray:[NSMutableArray array]];
    NSMutableArray *objectArray = [collisionObjects objects];
    for (id object in objectArray)
    {
        if ([[object valueForKey:@"type"] isEqualToString:@"Emitter"])
        {
            if ([[object valueForKey:@"BreakID"] intValue] != breakID)
            {
                continue;
            }
            
            float xVariance = 0;
            if ([[object valueForKey:@"XVariance"] length])
            {
                xVariance = [[object valueForKey:@"XVariance"] floatValue];
            }
            float yVariance = 0;
            if ([[object valueForKey:@"YVariance"] length])
            {
                yVariance = [[object valueForKey:@"YVariance"] floatValue];
            }
            
            NSString* emitterType = [object valueForKey:@"EmitterType"];
            if (![emitterType length]){continue;}
            emitterType = [NSString stringWithFormat:@"%@%@", emitterType, @".plist"];
            
            float x = [[object valueForKey:@"x"] floatValue];
            float y = [[object valueForKey:@"y"] floatValue];
            
            CCParticleSystemQuad *emitter = [CCParticleSystemQuad particleWithFile:emitterType];
            [[emitter texture] setAliasTexParameters];
            [emitter setAutoRemoveOnFinish:NO];
            [emitter setPositionType:kCCPositionTypeGrouped];
            [emitter setPosition:ccp(x, y)];
            
            if (xVariance != 0 || yVariance != 0)
            {
                [emitter setPosVar:CGPointMake(xVariance, yVariance)];
            }
            
            [parent addChild:emitter z:GroundZ-1];
            [_emitterArray addObject:emitter];
        }
    }
}

-(void)makeGroundBreak
{
    if (!hasBroken)
    {
        hasBroken = YES;
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:delay], [CCCallFunc actionWithTarget:self selector:@selector(breakGround)], nil]];
    }
}

-(void)breakGround
{
    for (CCParticleSystemQuad *emitter in _emitterArray)
    {
        [emitter resetSystem];
    }
    body->SetType(b2_dynamicBody);
}

-(void)resetGround
{
    hasBroken = NO;
    for (CCParticleSystemQuad *emitter in _emitterArray)
    {
        [emitter stopSystem];
    }
    body->SetUserData(nil);
    world->DestroyBody(body);
    [self setupBody];
    [self setupTriangulatedFixtures];
}

-(void)dealloc
{
    [self setEmitterArray:nil];
    [super dealloc];
}

-(void)handleContact:(b2Contact *)contact withImpulse:(const b2ContactImpulse *)impulse otherFixture:(b2Fixture *)otherFixture
{
    //If we need the other sprite from the fixture make sure to add another setup like below but for fixtures
    Box2DSprite *otherSprite = (Box2DSprite*)otherFixture->GetBody()->GetUserData();
    if (!otherSprite) {return;}
    
    if ([[otherSprite class] isSubclassOfClass:[Box2DSprite class]])
    {        
        if (otherSprite.gameObjectType == kBreakableGroundType)
        {
            if (![(BreakableGround*)otherSprite ignoreRocks])
            {
                [(BreakableGround*)otherSprite makeGroundBreak];
            }
        }
    }
}

@end
