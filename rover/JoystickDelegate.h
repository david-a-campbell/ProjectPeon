//
//  JoystickDelegate.h
//  rover
//
//  Created by David Campbell on 6/29/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JoystickDelegate <NSObject>
@optional
-(void)buttonPressBegan;
-(void)buttonPressEnded;
-(void)movementDidOccur:(CGPoint)movement;
-(BOOL)shouldRemoveFromAccelerationArray;
-(BOOL)shouldRemoveFromTouchArray;
@end
