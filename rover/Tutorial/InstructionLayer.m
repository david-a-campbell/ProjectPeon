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
#ifdef PROJECTPEON_MAC
#import "PeonWideScreen.h"
#endif

@implementation InstructionLayer

#ifdef PROJECTPEON_MAC
-(void)onEnter
{
    [super onEnter];
    [[PeonWideScreen sharedPresentation] setInstructionsVisible:YES];
}

-(void)onExit
{
    [[PeonWideScreen sharedPresentation] setInstructionsVisible:NO];
    [super onExit];
}
#endif

-(id)init
{
    if (self = [super init])
    {
        isFading = NO;
        checkState = YES;
        [self setTouchEnabled:YES];
        [self setupSprites];
        [self setupCheckbox];
#if PROJECTPEON_MAC
        // Fit the visible panel and footer (artwork rows 84 through 737),
        // rather than centering the image's unused top padding.
        menu.anchorPoint = CGPointZero;
        const CGFloat contentScale = 720.0 / 653.0;
        const CGPoint contentCenter = ccp(512.0, 357.5);
        for (CCNode *child in [self children])
        {
            CGPoint point = child.position;
            child.position = ccp(512.0 + (point.x - contentCenter.x) * contentScale,
                                 384.0 + (point.y - contentCenter.y) * contentScale);
            child.scaleX *= contentScale;
            child.scaleY *= contentScale;
        }
        CCSprite *wideGrid = [CCSprite spriteWithFile:@"MenuGridWide.png"];
        wideGrid.position = ccp(512,384);
        wideGrid.scaleX = (1024.0*4.0/3.0)/wideGrid.contentSize.width;
        wideGrid.scaleY = 768.0/wideGrid.contentSize.height;
        [self addChild:wideGrid z:-1 tag:9920];
#endif
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
#ifdef PROJECTPEON_MAC
    [[self getChildByTag:9920] runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
#endif
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
