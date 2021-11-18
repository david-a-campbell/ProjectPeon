//
//  LoadingLayer.m
//  rover
//
//  Created by David Campbell on 8/4/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "LoadingLayer.h"
#import "SaveManager.h"
#import "Constants.h"


@implementation LoadingLayer

-(id)initWithPlanetNum:(int)planetNum LevelNumber:(int)levelNum
{
    if ((self = [super init]))
    {
        [self setTouchEnabled:YES];
        [self setAnchorPoint:ccp(0,0)];
        [self setPosition:ccp(0, 0)];
        screen = [CCSprite spriteWithFile:[NSString stringWithFormat:@"loadingScreen%i.png", planetNum]];
        [screen setAnchorPoint:ccp(0, 0)];
        [screen setPosition:ccp(0, 0)];
        [screen setScale:(2*SCREEN_SCALE)];
        [self addChild:screen];
        
        CCTexture2DPixelFormat currentFormat = [CCTexture2D defaultAlphaPixelFormat];
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA4444];
        
        scoreLabel = [[CCLabelBMFont labelWithString:@"" fntFile:@"font110.fnt"] retain];
        levelLabel = [[CCLabelBMFont labelWithString:@"" fntFile:@"font52.fnt"] retain];
        [scoreLabel setPosition:ccp(830.5, 387)];
        [levelLabel setPosition:ccp(830.5, 438.5)];
        [scoreLabel setScale:SCREEN_SCALE];
        [levelLabel setScale:SCREEN_SCALE];
        [self addChild:scoreLabel];
        [self addChild:levelLabel];

        int score = [[SaveManager sharedManager] getPercentageScoreForPlanet:planetNum Level:levelNum];
        [scoreLabel setString:[NSString stringWithFormat:@"%i%%", score]];

        if (levelNum < 10) {
            [levelLabel setString:[NSString stringWithFormat:@"Level 0%i", levelNum]];
        }else {
            [levelLabel setString:[NSString stringWithFormat:@"Level %i", levelNum]];
        }
        
        [CCTexture2D setDefaultAlphaPixelFormat:currentFormat];
        
        double delayInSeconds = 0.7;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
        {
            [self showActivityIndicator];
        });
    }
    return self;
}

-(void)dealloc
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [scoreLabel release];
    [levelLabel release];
    [super dealloc];
}

-(void)showActivityIndicator
{
    activityIndicatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loadingIcon"]];
    [activityIndicatorView setUserInteractionEnabled:NO];
    activityIndicatorView.center = ccp(946, 690);
    [[activityIndicatorView layer] addAnimation:[self animationForSpinning] forKey:@"rotationAnimation"];
    [[[CCDirector sharedDirector] view] addSubview:activityIndicatorView];
    [activityIndicatorView release];
}

-(CCSequence*)fadeOutSequence
{
    return [CCSequence actions:[CCCallFunc actionWithTarget:self selector:@selector(fadeOut)], [CCDelayTime actionWithDuration:0.5], nil];
}

-(void)fadeOut
{
    [activityIndicatorView removeFromSuperview];
    [screen runAction:[CCFadeTo actionWithDuration:0.5 opacity:0]];
    [scoreLabel runAction:[CCFadeTo actionWithDuration:0.5 opacity:0]];
    [levelLabel runAction:[CCFadeTo actionWithDuration:0.5 opacity:0]];
}

- (CAAnimation *)animationForSpinning
{
    CABasicAnimation* animation;
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = [NSNumber numberWithFloat:M_PI_2];
    animation.duration = 0.20;
    animation.cumulative = YES;
    animation.repeatCount = 10000;
    return animation;
}

- (void)registerWithTouchDispatcher
{
    //Must have negative priority to block ccmenuItems behind
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-1000 swallowsTouches:YES];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    //Must return yes to swallow touches
    return YES;
}

@end
