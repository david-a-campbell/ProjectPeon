//
//  Pod.h
//  rover
//
//  Created by David Campbell on 7/21/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"
#import "PodRamp.h"
#import "BoostDustProtocol.h"

@interface Pod : Box2DSprite <PodRampDelegate, BoostDustProtocol>
{
    b2World *world;
    CGPoint backGroundOffset;
    CGPoint originalPosition;
    b2Vec2 doorVector1;
    b2Vec2 doorVector2;
    b2Fixture *door;
    b2Body *counterBody;
    b2Body *cartTouchBody;
    CCSprite *podDoor;
    BOOL shouldFireBooster;
    float cartWeight;
    CCLayer *parentLayer;
    CCParticleSystemQuad *blastEmitter;
    CCSprite* podBackground;
    PodRamp* podRamp;
    ALuint soundEffectKey;
}

-(id)initWithWorld:(b2World *)theWorld atLocation:(CGPoint)location andLayer:(CCLayer*)layer;
-(void)closeDoor;
-(void)openDoor;
-(void)resetPod;
-(void)liftOffWithWeight:(float)weight;
-(int)countPeons;
@end
