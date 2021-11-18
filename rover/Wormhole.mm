//
//  Wormhole.m
//  rover
//
//  Created by David Campbell on 7/15/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Wormhole.h"
#import "cocos2d.h"
#import "BaseParallaxLayer.h"
#import "Box2DHelpers.h"

@implementation Wormhole

- (id)initAtLocation:(CGPoint)location andLayer:(BaseParallaxLayer*)lyr andPeonCount:(int)peons world:(b2World*)theWorld
{
    if ((self = [super init]))
    {
        soundEffectKey =  0;
        world = theWorld;
        pause = NO;
        numberOfPeons = peons;
        [self setGameObjectType:kWormholeType];
        layer = lyr;
        [self setPosition:location];
        [self setupParticleEmitter];
    }
    return self;
}

-(void)createBodyAtLocation:(CGPoint)location
{
    b2BodyDef bd;
    bd.position = b2Vec2(location.x/pixelsToMeterRatio(), location.y/pixelsToMeterRatio());
    bd.type = b2_staticBody;
    body = world->CreateBody(&bd);
    body->SetUserData(self);
    
    b2CircleShape shape;
    float radius = 250;
    shape.m_radius = radius/pixelsToMeterRatio();
    
    b2FixtureDef _fixtureDef;
    _fixtureDef.isSensor = true;
    _fixtureDef.shape = &shape;
    sensorFixture = body->CreateFixture(&_fixtureDef);
    sensorFixture->SetUserData(self);
}

-(void)setupParticleEmitter
{
    holeEmitter = [CCParticleSystemQuad particleWithFile:@"wormhole.plist"];
    [holeEmitter setPositionType:kCCPositionTypeGrouped];
    [holeEmitter setScale:2.0f];
    [holeEmitter setPosition: [self position]];
    [layer addChild:holeEmitter z:-500+2];
    [holeEmitter stopSystem];
}

-(void)spawnPeons
{
    [[GameManager sharedGameManager] stopSoundEffect:soundEffectKey];
    soundEffectKey = [self playSoundEffect:@"tornado.mp3"];
    
    [self createBodyAtLocation:[self position]];
    
    numberSpawned = 0;
    [holeEmitter resetSystem];
    id seq = [CCSequence actions:[CCDelayTime actionWithDuration:1.0], [CCCallFunc actionWithTarget:self selector:@selector(spawnAPeon)],nil];
    [self runAction:seq];
}

-(void)spawnAPeon
{
    if (numberOfPeons > numberSpawned) 
    {
        numberSpawned++;
        [layer createThingySpriteAtLocation:[self position] dynamic:YES];
        id seq = [CCSequence actions:[CCDelayTime actionWithDuration:0.5], [CCCallFunc actionWithTarget:self selector:@selector(spawnAPeon)],nil];
        [self runAction:seq];
    }else {
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.0], [CCCallFunc actionWithTarget:self selector:@selector(finishPeonSpawn)], nil]];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BEGIN_GAMEPLAY object:nil];
    }
}

-(void)finishPeonSpawn
{
    [holeEmitter stopSystem];
    [self destroySensor];
}

-(int)peonCount
{
    return numberOfPeons;
}

-(void)destroySensor
{
    if (sensorFixture)
    {
        body->DestroyFixture(sensorFixture);
        world->DestroyBody(body);
        sensorFixture = nil;
    }
}

-(void)resetWormhole
{
    [self destroySensor];
    [self stopAllActions];
    [holeEmitter stopSystem];
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    if (!sensorFixture){return;}
    
    float forceAmount = 50;
    
    NSMutableArray *forcedArray = [NSMutableArray array];
    b2ContactEdge* edge = body->GetContactList();
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching())
        {
            b2Fixture* fixtureB = contact->GetFixtureA();
            b2Body *bodyB = fixtureB->GetBody();
            Box2DSprite *spriteB = (Box2DSprite*)bodyB->GetUserData();
            if (fixtureB->IsSensor() || [forcedArray containsObject:spriteB])
            {
                edge = edge->next;
                continue;
            }
            
            if (spriteB != nil && spriteB != self && spriteB.gameObjectType == kPlayerCartType)
            {
                b2WorldManifold manifold;
                contact->GetWorldManifold(&manifold);
                b2Vec2 worldPoint = manifold.points[0];
                b2Vec2 center = b2Vec2([self position].x/pixelsToMeterRatio(), [self position].y/pixelsToMeterRatio());
                b2Vec2 forceVector = b2Vec2(worldPoint.x-center.x, worldPoint.y-center.y);
                forceVector.Normalize();
                
                b2Vec2 force = b2Vec2(forceAmount * forceVector.x, forceAmount * forceVector.y);
                
                b2Vec2 finalForce = b2Vec2(force.x * bodyB->GetMass(), force.y * bodyB->GetMass());
                bodyB->ApplyForceToCenter(finalForce);
                bodyB->ApplyAngularImpulse(-forceAmount/3 * bodyB->GetMass());
                [forcedArray addObject:spriteB];
            }
        }
        edge = edge->next;
    }
    [forcedArray removeAllObjects];
}
-(void)sceneEnd
{
    [[GameManager sharedGameManager] stopSoundEffect:soundEffectKey];
}

@end
