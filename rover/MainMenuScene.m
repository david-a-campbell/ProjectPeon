//
//  MainMenuScene.m
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "MainMenuScene.h"
#import "LevelSelectLayer.h"

@implementation MainMenuScene

-(id)init
{
    if ((self = [super init]))
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"MainMenuAtlas.plist"];
        
        [self setAnchorPoint:CGPointMake(0, 0)];
        levelSelectLayer = [[LevelSelectLayer alloc] init];
        [self addChild:levelSelectLayer];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    return self;
}

-(void)dealloc
{
    [levelSelectLayer release];
    levelSelectLayer = nil;
    [super dealloc];
}

@end
