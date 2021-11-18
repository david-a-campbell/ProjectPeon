//
//  ShockImageSet.h
//  rover
//
//  Created by David Campbell on 8/1/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface ShockImageSet : NSObject
@property (nonatomic, retain) CCSprite *tempShock;
@property (nonatomic, retain) CCSprite *tempShockBar;
@property (nonatomic, retain) CCSprite *tempShockBolt1;
@property (nonatomic, retain) CCSprite *tempShockBolt2;
@property (nonatomic, retain) CCSprite *tempShockPiston;
@property (nonatomic, assign) float tempShockBarOriginalLength;
@property (nonatomic, assign) float tempShockPistonOriginalLength;
@property (nonatomic, assign) float tempShockBoltOriginalHeight;
@end
