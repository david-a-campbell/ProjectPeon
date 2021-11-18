//
//  Booster.h
//  rover
//
//  Created by David Campbell on 5/26/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartPart.h"
#import "JoystickDelegate.h"
#import "BoostDustProtocol.h"

@interface Booster : CartPart <JoystickDelegate, BoostDustProtocol>
{
    float rotationOffset;
    BOOL shouldFireBooster;
    CCParticleSystemQuad *blastEmitter;
    CCLayer *layer;
    BOOL ranOutOfFuel;
    float boostFollow;
    float boost;
}
@property (assign) b2Fixture *sensorFixture;
- (id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart*)theCart andLayer:(CCLayer *)lyr andType:(GameObjectType)type;
-(b2PolygonShape*)createShapeForCenter:(b2Vec2)center;
-(b2PolygonShape*)createShape;
-(void)createDustForGround:(b2Fixture*)groundFix point:(b2Vec2)point;
@end
