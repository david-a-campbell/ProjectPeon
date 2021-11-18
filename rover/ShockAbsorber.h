//
//  shockAbsorber.h
//  rover
//
//  Created by David Campbell on 3/13/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartPart.h"

@interface ShockAbsorber : CartPart
{
    b2Joint *joint;
    b2Fixture *fixture1;
    b2Fixture *fixture2;
    b2Vec2 adjPivot1;
    b2Vec2 adjPivot2;
    BOOL setupSuccessful;
    
    CCSprite *ShockBar;
    CCSprite *ShockPiston;
    CCSprite *Bolt1;
    CCSprite *Bolt2;
    float BoxOriginalWidth;
    float ShockBarOriginalLength;
    float BoltOriginalHeight;
    float BoxOriginalHeight;
    float BoxAdjustedWidth;
}
- (id)initWithStart:(CGPoint)touchStartLocation andEnd: (CGPoint)touchEndLocation andCart:(PlayerCart *)theCart;
-(void)setPositionWithPoint:(CGPoint)posA andPoint:(CGPoint)posB;
@property (assign) b2Joint *joint;
@property (assign) b2Fixture *fixture1;
@property (assign) b2Fixture *fixture2;
@property (readonly) BOOL setupSuccessful;

-(BOOL)moveJointFrom:(b2Fixture*)oldFix to:(b2Fixture*)newFix;
-(void)setupJoint;
-(void)swapPoints;
@end
