//
//  Motor.h
//  rover
//
//  Created by David Campbell on 3/11/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Wheel.h"
#import "JoystickDelegate.h"

@interface Motor : Wheel <JoystickDelegate>
{
    CCSprite *MotorHub;
    float torque;
    float maxRevsSec;
}
@end
