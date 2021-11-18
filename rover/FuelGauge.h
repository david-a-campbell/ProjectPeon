//
//  FuelGauge.h
//  rover
//
//  Created by David Campbell on 6/14/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "CCProgressTimer.h"
@class PlayerCart;

@interface FuelGauge : CCProgressTimer
{
    PlayerCart *cart;
    float maxGauge;
}

-(id)initWithPlayerCart:(PlayerCart*)playerCart  atPosition:(CGPoint)position;
-(void)fadeOut;
-(void)fadeIn;

@end
