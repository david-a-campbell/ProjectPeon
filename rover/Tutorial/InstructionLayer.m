//
//  InstructionLayer.m
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "InstructionLayer.h"
#import "Constants.h"
#import "AnimatedSprite.h"
#import "SaveManager.h"

@implementation InstructionLayer

-(id)init
{
    if (self = [super init])
    {
        isFading = NO;
        checkState = YES;
        [self setTouchEnabled:YES];
        [self setupSprites];
        [self setupCheckbox];
    }
    return self;
}

-(void)setupSprites
{
    background = [CCSprite spriteWithFile:@"tutorials.png"];
    [background setScale:2*SCREEN_SCALE];
    [background setPosition: ccp(512.0, 384.0)];
    [self addChild:background];
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"BuildFrames.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"CatchFrames.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"DriveFrames.plist"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"Build" forKey:@"SpriteName"];
    [dict setValue:@"build" forKey:@"AnimationToRun"];
    [dict setValue:@"1" forKey:@"Repeat"];
    buildAnim = [[AnimatedSprite alloc] initWithDict:dict];
    [buildAnim setScale:2*SCREEN_SCALE];
    [buildAnim setPosition:ccp(178, 445)];
    
    [dict setValue:@"Catch" forKey:@"SpriteName"];
    [dict setValue:@"catch" forKey:@"AnimationToRun"];
    catchAnim = [[AnimatedSprite alloc] initWithDict:dict];
    [catchAnim setScale:2*SCREEN_SCALE];
    [catchAnim setPosition:ccp(512, 445)];
    
    [dict setValue:@"Drive" forKey:@"SpriteName"];
    [dict setValue:@"drive" forKey:@"AnimationToRun"];
    driveAnim = [[AnimatedSprite alloc] initWithDict:dict];
    [driveAnim setScale:2*SCREEN_SCALE];
    [driveAnim setPosition:ccp(846, 445)];
    
    [self addChild:buildAnim];
    [self addChild:catchAnim];
    [self addChild:driveAnim];
    
    [buildAnim release];
    [driveAnim release];
    [catchAnim release];
}

-(void)setupCheckbox
{
    checkState = [[SaveManager sharedManager] getShowTutorialState];
    
    CCMenuItemImage *on = [CCMenuItemImage itemWithNormalImage:@"tutorialCheck_2.png" selectedImage:@"tutorialCheck_2.png"];
    CCMenuItemImage *off = [CCMenuItemImage itemWithNormalImage:@"tutorialCheck_1.png" selectedImage:@"tutorialCheck_1.png"];
    
    if (checkState)
    {
        checkBox = [CCMenuItemToggle itemWithTarget:self selector:@selector(checkStateChange) items:on, off, nil];
    }else
    {
        checkBox = [CCMenuItemToggle itemWithTarget:self selector:@selector(checkStateChange) items:off, on, nil];
    }
    
    [checkBox setScale:2*SCREEN_SCALE];
    menu = [CCMenu menuWithItems:checkBox, nil];
    [menu setPosition:ccp(272.0, 44.5)];
    [self addChild:menu z:2];
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.2], [CCCallFunc actionWithTarget:self selector:@selector(changeMenuPriority)], nil]];
}

-(void)changeMenuPriority
{
    [menu setHandlerPriority:-2001];
}
     
-(void)checkStateChange
{
    checkState = !checkState;
    [[SaveManager sharedManager] setShowTutorialState:checkState];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!isFading)
    {
        [self fadeAway];
    }

    return YES;
}

- (void)registerWithTouchDispatcher
{
    //Must have negative priority to block ccmenuItems behind
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-2000 swallowsTouches:YES];
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(void)fadeAway
{
    isFading = YES;
    [background runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
    [buildAnim runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
    [driveAnim runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
    [catchAnim runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
    [menu runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
    
    CCSequence *seq = [CCSequence actions:[CCDelayTime actionWithDuration:0.3], [CCCallFunc actionWithTarget:self selector:@selector(removeSelf)],nil];
    [self runAction:seq];
}

-(void)removeSelf
{
    [self removeFromParentAndCleanup:YES];
}

-(void)dealloc
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"BuildFrames.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"CatchFrames.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"DriveFrames.plist"];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    [[self delegate] instructionsWillBeRemoved];
    [super dealloc];
}

@end
