//
//  Wormhole.h
//  rover
//
//  Created by David Campbell on 7/15/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"
@class CCParticleSystemQuad;
@class BaseParallaxLayer;

@interface Wormhole : Box2DSprite
{
    int numberOfPeons;
    int numberSpawned;
    BaseParallaxLayer *layer;
    CCParticleSystemQuad *holeEmitter;
    b2Fixture *sensorFixture;
    BOOL pause;
    ALuint soundEffectKey;
    b2World *world;
}
- (id)initAtLocation:(CGPoint)location andLayer:(BaseParallaxLayer*)lyr andPeonCount:(int)peons world:(b2World*)theWorld;

-(void)spawnPeons;
-(void)resetWormhole;
-(int)peonCount;

@end
