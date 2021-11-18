//
//  BaseGameScene.m
//  rover
//
//  Created by David Campbell on 8/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "BaseGameScene.h"
#import "BaseActionLayer.h"
#import "CartCreationLayer.h"
#import "ForeGroundParallaxLayer.h"
#import "BacgroundParallaxLayer.h"
#import "SkyboxParallaxLayer.h"
#import "PopupMenu.h"
#import "SaveMenu.h"
#import "LoadingLayer.h"
#import "GameManager.h"
#import "SaveManager.h"
#import "ControlsLayer.h"

@interface BaseGameScene()
{
    CartCreationLayer *creationLayer;
}
@end

@implementation BaseGameScene

-(id)initWithPlanet:(int)pNum andLevel:(int)lNum
{
    self = [super init];
    if (self)
    {
        planetNum = pNum;
        levelNum = lNum;
        
        if ([[SaveManager sharedManager] getShowTutorialState])
        {
            InstructionLayer *instructions = [[InstructionLayer alloc] init];
            [instructions setDelegate:self];
            [self addChild:instructions z:7];
            [instructions release];
        }else
        {
            [self displayLoadingScreen];
        }
    }
    return self;
}

-(void)instructionsWillBeRemoved
{
    [self displayLoadingScreen];
}

-(void)displayLoadingScreen
{
    loadingLayer = [[LoadingLayer alloc] initWithPlanetNum:planetNum LevelNumber:levelNum];
    [self addChild:loadingLayer z:90000];
    [loadingLayer release];
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1], [CCCallFunc actionWithTarget:self selector:@selector(setupWorld)], nil]];
}

-(void)setupWorld
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"menuItemsAtlas.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"spriteAtlas.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"spriteAtlas2.plist"];
    
    CGPoint tmxMapping = [[GameManager sharedGameManager] currentTmxMaping];
    int tmxPNum = tmxMapping.x;
    int tmxLNum = tmxMapping.y;
    
    NSString *tmxName = [NSString stringWithFormat:@"planet%iLevel%i.tmx", tmxPNum, tmxLNum];
    NSString *animSpriteFrames = [NSString stringWithFormat:@"Planet%i_AnimatedSprites.plist", tmxPNum];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile: animSpriteFrames];
    
    BaseActionLayer *actionLayer = [[BaseActionLayer alloc] initWithTileMapName:tmxName];
    ControlsLayer *controlsLayer = [[ControlsLayer alloc] init];
    creationLayer = [[CartCreationLayer alloc] initwithLayerToFollow:actionLayer andDelegate:actionLayer topLayer:controlsLayer];
    ForeGroundParallaxLayer *fgLayer = [[ForeGroundParallaxLayer alloc] initWithTileMap:[actionLayer TileMapName]];
    BacgroundParallaxLayer *bgLayer = [[BacgroundParallaxLayer alloc] initWithTileMap:[actionLayer TileMapName]];
    SkyboxParallaxLayer *sbLayer = [[SkyboxParallaxLayer alloc] initWithTileMap:[actionLayer TileMapName]];
    
    [actionLayer setControlsDelegate:controlsLayer];
    [controlsLayer setActionLayer:actionLayer];
    
    [actionLayer addParallaxLayer:fgLayer];
    [actionLayer addParallaxLayer:bgLayer];
    [actionLayer addParallaxLayer:sbLayer];
    
    [self addChild:sbLayer z:0];
    [self addChild:bgLayer z:1];
    [self addChild:actionLayer z:2];
    [self addChild:fgLayer z:3];
    [self addChild:creationLayer z:4];
    [self addChild:[creationLayer levelScoreDisplay] z:5];
    [self addChild:controlsLayer z:6];
    
    [actionLayer setPosition:[actionLayer position]];
    
    [controlsLayer release];
    [creationLayer release];
    [actionLayer release];
    [fgLayer release];
    [bgLayer release];
    [sbLayer release];
    [self loadComplete];
}

-(void)loadComplete
{    
    [self runAction:[CCSequence actions:[loadingLayer fadeOutSequence], [CCCallFunc actionWithTarget:self selector:@selector(removeLoadingLayer)], nil]];
}

-(void)removeLoadingLayer
{
    [loadingLayer removeFromParentAndCleanup:YES];
    loadingLayer = nil;
//    [[AdManager sharedAdManager] setShouldDisplayInterstitialAd:NO];
}

-(void)dealloc
{
    [super dealloc];
}

@end

