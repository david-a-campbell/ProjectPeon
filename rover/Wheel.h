//
//  Wheel.h
//  rover
//
//  Created by David Campbell on 3/10/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartPart.h"

@interface Wheel : CartPart
{
    CCSprite *pivotIndicator;
    CGFloat rotationOffset;
    BOOL doesSwivel;
}
@property (assign) b2Fixture *buoyancyFixture;
@property (assign) b2Body *swivelBody;
@property (assign) b2Joint *joint;

- (id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart*)theCart andType:(GameObjectType)type;
-(void)setupWheelJointWithBody:(b2Body*)foundPartBody;
-(b2Body*)getSwivelBody;
-(void)addPivotIndicator;
-(void)showPivotIndicator;
-(void)hidePivotIndicator;
-(b2CircleShape*)createShapeForCenter:(b2Vec2)center;
-(b2CircleShape*)createShape;
-(void)createBuoyancyFixture;
@end
