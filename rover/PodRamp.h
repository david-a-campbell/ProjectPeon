//
//  PodRamp.h
//  rover
//
//  Created by David Campbell on 7/21/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@protocol PodRampDelegate <NSObject>
-(void)rampRetracted;
@end

@interface PodRamp : Box2DSprite
{
    b2World *world;
    CGPoint originalPosition;
    CCSprite *podRamp1;
    CCSprite *podRamp2;
    b2Body *limitBody;
}
@property (nonatomic, assign) id<PodRampDelegate> delegate;
-(id)initWithWorld:(b2World *)theWorld atLocation:(CGPoint)location withBody:(b2Body*)passedBody;
-(void)removeRampPhysics;
-(void)retractRamp;
@end
