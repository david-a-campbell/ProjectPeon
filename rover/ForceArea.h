//
//  ForceArea.h
//  rover
//
//  Created by David Campbell on 6/15/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@interface ForceArea : Box2DSprite
{
    int forceID;
    b2World *world;
    CGPoint forceVector;
    float forceAmount;
    b2Fixture *fixtureA;
    BOOL isBuoyancyArea;
    float liquidDensity;
    BOOL emitterFollowsScreen;
    BOOL allowFullScreenEmitter;
    
    float time;
    float stopTime;
}
@property (nonatomic, retain) NSMutableArray *emitterArray;
-(void)beginForceCycle;
-(void)resetForceCycle;
-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld objectGroup:(CCTMXObjectGroup*)spriteObjects andParent:(CCNode*)parent;
@end
