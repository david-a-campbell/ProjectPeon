//
//  ControlsLayer.h
//  rover
//
//  Created by David Campbell on 6/29/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "CCLayer.h"
#import "ControlsDelegate.h"
#import "SneakyButton.h"
#import "SneakyJoystick.h"
#import "SneakyButtonSkinnedBase.h"
#import "SneakyJoystickSkinnedBase.h"
#import "JoystickDelegate.h"

@interface ControlsLayer : CCLayer <ControlsDelegate>
{
    SneakyJoystick *joystick;
    SneakyButton *button;
    SneakyJoystickSkinnedBase *joystickBase;
    SneakyButtonSkinnedBase *buttonBase;
    BOOL useTouch;
    BOOL buttonBecameActive;
    BOOL controlsEnabled;
    UIAcceleration *accel;
    UITouch *joystickTouch;
    CGPoint currentMovement;
}
@property (nonatomic, assign) NSObject<JoystickDelegate> *actionLayer;
@end
