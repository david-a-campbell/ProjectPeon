//
//  AnimatedSprite.m
//  rover
//
//  Created by David Campbell on 7/11/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "AnimatedSprite.h"

@implementation AnimatedSprite

-(id)initWithDict:(id)dict
{
    if (self = [super init])
    {
        [self setOriginalPosition:ccp(0, 0)];
        [self setupAnimationsWithDict:dict];
        [self setupNotifications];
        if (startsOn)
        {
            [self beginAnimation];
        }
    }
    return self;
}

-(void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAnimation) name:NOTIFICATION_RESET_GAMEPLAY object:nil];
    startsOn = YES;
    if (triggerId != 0)
    {
        startsOn = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerAnimation:) name:NOTIFICATION_TRIGGER_SPRITE object:nil];
    }
}

-(void)dealloc
{
    [self stopAllActions];
    [animationToRun release];
    animationToRun = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setAnimations:nil];
    [super dealloc];
}

-(void)setupAnimationsWithDict:(id)dict
{
    if ([[dict valueForKey:@"SpriteName"] length])
    {
        NSString *animationPlist = [NSString stringWithFormat:@"%@.plist", [dict valueForKey:@"SpriteName"]];
        [self setAnimations:[self animationDictFromPlist:animationPlist]];
    }
    
    animationToRun = [[dict valueForKey:@"AnimationToRun"] retain];
    
    repeats = [[dict valueForKey:@"Repeat"] intValue];
    timeToMove = [[dict valueForKey:@"TimeToMove"] floatValue];
    moveDelay = [[dict valueForKey:@"MoveDelay"] floatValue];
    float moveX = [[dict valueForKey:@"MoveX"] floatValue];
    float moveY = [[dict valueForKey:@"MoveY"] floatValue];
    triggerId = [[dict valueForKey:@"TriggerID"] intValue];
    rotation = [[dict valueForKey:@"Rotation"] floatValue];
    flipX = [[dict valueForKey:@"FlipX"] intValue];
    flipY = [[dict valueForKey:@"FlipY"] intValue];
    moveByPoint = ccp(moveX, moveY);
    
    CCAnimation *animation = [_animations valueForKey:animationToRun];
    [self setDisplayFrame:[[[animation frames] objectAtIndex:0] spriteFrame]];
    if (repeats)
    {
        [self setOpacity: 0];
    }
    
    [self setRotation:rotation];
    [self setFlipX:flipX];
    [self setFlipY:flipY];
}

-(void)setOriginalPosition:(CGPoint)originalPosition
{
    _originalPosition = originalPosition;
    [self setPosition:originalPosition];
}

-(void)resetAnimation
{
    [self stopAllActions];
    [self setPosition:_originalPosition];
    CCAnimation *animation = [_animations valueForKey:animationToRun];
    [self setDisplayFrame:[[[animation frames] objectAtIndex:0] spriteFrame]];
    
    if (repeats)
    {
        [self setOpacity: 0];
    }
    if (startsOn)
    {
        [self beginAnimation];
    }
}

-(void)beginAnimation
{    
    CCAnimation *animation = [_animations valueForKey:animationToRun];
    for (CCAnimationFrame *frame in [animation frames])
    {
        [[[frame spriteFrame] texture] setAliasTexParameters];
    }
    
    id action = [CCAnimate actionWithAnimation:animation];
    id repeatAction = action;
    if (repeats)
    {
        repeatAction = [CCRepeatForever actionWithAction:action];
    }
    
    CCSequence *removeSequence = nil;
    if(!CGPointEqualToPoint(ccp(0, 0), moveByPoint))
    {
        id moveAction = [CCMoveBy actionWithDuration:timeToMove position:moveByPoint];
        removeSequence = [CCSequence actions: [CCDelayTime actionWithDuration:moveDelay], moveAction, [CCCallFunc actionWithTarget:self selector:@selector(endAnimations)],nil];
    }
    
    [self setOpacity: 255];
    [self runAction:repeatAction];
    if (removeSequence)
    {
        [self runAction:removeSequence];
    }
}

-(void)endAnimations
{
    [self setOpacity:0];
    //[self beginAnimation];
}

-(void)triggerAnimation:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    int tID= [[userInfo objectForKey:@"TriggerID"] intValue];
    if (triggerId == tID)
    {
        [self beginAnimation];
    }
}

@end
