//
//  LevelSelectMenuItem.m
//  rover
//
//  Created by David Campbell on 6/17/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "LevelSelectMenuItem.h"
#import "Constants.h"
#import "SaveManager.h"

@implementation LevelSelectMenuItem
@synthesize levelNum, planetNum, delegate;

-(id)initWithState:(BOOL)state andLevelNum:(int)indx planetNum:(int)planet
{
    if ((self = [super init])) 
    {
        [self setPlanetNum:planet];
        [self setLevelNum: indx];
        [self setupButtonWithState:state];
    }
    return self;
}

-(void)dealloc
{
    [numLabel release];
    numLabel = nil;
    if (scoreLabel != nil) {
        [scoreLabel release];
        scoreLabel = nil;
    }
    [super dealloc];
}

-(void)setupButtonWithState:(BOOL)state
{
    isUnlocked = state;
    NSString *foreString = @"0";
    if (levelNum > 9) {foreString = @"";}
    CCTexture2DPixelFormat currentFormat = [CCTexture2D defaultAlphaPixelFormat];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA4444];
    numLabel = [[CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%@%i", foreString, levelNum] fntFile:@"fontBlk.fnt"] retain];
    [numLabel setPosition:ccp(109/(4*(SCREEN_SCALE)), 164/(4*(SCREEN_SCALE)))];
    if (!isUnlocked) {
        [numLabel setPosition:ccp(109/(4*(SCREEN_SCALE)), 94/(4*(SCREEN_SCALE)))];
    }else {
        scoreLabel = [[CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%i%%", [self score]] fntFile:@"font.fnt"] retain];
        [scoreLabel setPosition:ccp(109/(4*(SCREEN_SCALE)), 90/(4*(SCREEN_SCALE)))];
        [scoreLabel setScale:0.75];
    }
    [numLabel setScale:0.5];
    [CCTexture2D setDefaultAlphaPixelFormat:currentFormat];   
    
    CCSprite *unlocked = [CCSprite spriteWithSpriteFrameName:@"levelSelect_levelUnlocked_1.png"];
    CCSprite *unlockedSel = [CCSprite spriteWithSpriteFrameName:@"levelSelect_levelUnlocked_sel_1.png"];
    CCSprite *dissabled;
    if (isUnlocked) {
        dissabled = [CCSprite spriteWithSpriteFrameName:@"levelSelect_levelUnlocked_1.png"];
    }else {
        dissabled = [CCSprite spriteWithSpriteFrameName:@"levelSelect_levelLocked_1.png"];
    }
    
    button = [CCMenuItemSprite itemWithNormalSprite:unlocked selectedSprite:unlockedSel disabledSprite:dissabled target:self selector:@selector(loadLevel)];
    [button setScale:2.0*(SCREEN_SCALE)];
    [button setAnchorPoint:ccp(0, 0)];
    [button addChild:numLabel];
    if (scoreLabel != nil) {
        [button addChild:scoreLabel];
    }
    [self addChild:button];
    [self enable];
}

-(int)score
{
    return [[SaveManager sharedManager] getPercentageScoreForPlanet:planetNum Level:levelNum];
}

-(void)loadLevel
{
    [delegate loadLevelSelected:levelNum];
}

-(void)enable
{
    [button setIsEnabled:isUnlocked];
}

-(void)dissable
{
    [button setIsEnabled:NO];
}

-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:NO];
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

@end