//
//  FuelGauge.m
//  rover
//
//  Created by David Campbell on 6/14/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "FuelGauge.h"
#import "PlayerCart.h"
#import "SaveManager.h"

#define GAUGE_MAX 66.0f;
#define GAUGE_MAX_UPGRADE 100.0f

@implementation FuelGauge

-(id)initWithPlayerCart:(PlayerCart*)playerCart atPosition:(CGPoint)position
{
    if (self = [super init])
    {
        [self setGaugeMax];
        cart = playerCart;
        [self setType:kCCProgressTimerTypeRadial];
        [self setupImage];
        [self scheduleUpdate];
        [self setPosition:position];
        [self setOpacity:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemPurchased:) name:NOTIFICATION_PURCHASED_ITEM object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

-(void)setupImage
{
    CCSprite *sprite = [CCSprite spriteWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"boostMeter.png"]];
    [self setSprite:sprite];
    [self setScale:SCREEN_SCALE];
}

-(void)update:(ccTime)dt
{
    [self setPercentage:([cart fuel]/[cart maxFuel])*maxGauge];
}

-(void)fadeOut
{
    id fadeAction = [CCFadeTo actionWithDuration:0.2f opacity:0];
    [self runAction:fadeAction];
}

-(void)fadeIn
{
    id fadeAction = [CCFadeTo actionWithDuration:0.2f opacity:255];
    [self runAction:fadeAction];
}

-(void)itemPurchased:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSString *pID= [userInfo objectForKey:@"ProductID"];
    if ([pID isEqualToString:PRODUCT_BOOST_50])
    {
        maxGauge = GAUGE_MAX_UPGRADE;
    }
}

-(void)setGaugeMax
{
    if ([[SaveManager sharedManager] hasBooster50Unlocked])
    {
        maxGauge = GAUGE_MAX_UPGRADE;
    }else
    {
        maxGauge = GAUGE_MAX;
    }
}

@end
