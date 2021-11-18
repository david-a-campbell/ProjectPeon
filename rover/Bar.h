//
//  Bar.h
//  rover
//
//  Created by David Campbell on 3/9/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartPart.h"
@interface Bar : CartPart
{
    float rotationOffset;
}
@property (assign) b2Fixture *sensorFixture;
- (id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart*)theCart;
-(b2PolygonShape*)createShapeForCenter:(b2Vec2)center;
-(b2PolygonShape*)createShape;
-(void)createSensor;

@end
