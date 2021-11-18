//
//  Elevator.h
//  rover
//
//  Created by David Campbell on 6/23/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"
#import "CommonProtocols.h"
@class PlayerCart;

@interface Elevator : Box2DSprite
{
    CGSize plankSize;
    float height;
    float width;
    b2World *world;
    b2Body *anchorBody;
    NSString *direction;
    ElevatorDirection elevatorDirection;
    float x, y;
    float time;
    float stopTime1;
    float stopTime2;
    CGPoint sPosition;
    CGPoint fPosition;
    CharacterStates nextState;
    BOOL reversed;
    float elapsedTime;
    int triggerId;
}
-(void)beginMovement;
-(void)resetElevator;
-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld;
@end
