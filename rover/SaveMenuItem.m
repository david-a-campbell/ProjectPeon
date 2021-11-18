//
//  SaveMenuItem.m
//  rover
//
//  Created by David Campbell on 5/30/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "SaveMenuItem.h"
#import "Constants.h"
#import "SaveManager.h"
#import "ToolTipMenu.h"

@implementation SaveMenuItem
@synthesize  index, saveDelegate;

-(id)initWithImage:(UIImage *)image andIndex:(int)indx
{
    if ((self = [super init]))
    {
        index = indx;
        [self setupImage:image];
        isExpanded = NO;
    }
    return self;
}

-(id)initAsSaveItem
{
    if ((self = [super init]))
    {
        index = 0;
        CCSprite *backing = [CCSprite spriteWithSpriteFrameName:@"blueprints_btn_new_1.png"];
        CCSprite *backingSel = [CCSprite spriteWithSpriteFrameName:@"blueprints_btn_new_sel_1.png"];
        button = [CCMenuItemSprite itemWithNormalSprite:backing selectedSprite:backingSel disabledSprite:nil target:self selector:@selector(saveCart)];
        [button setScale:2*(SCREEN_SCALE)];
        [self addChild:button];
        [self dissable];
        [self setOpacity:0];
    }
    return self;
}

-(void)dealloc
{
    [savedImage release];
    savedImage = nil;
    [super dealloc];
}

-(void)setupImage:(UIImage *)image
{
    savedImage = [[CCSprite spriteWithCGImage:[image CGImage] key:nil] retain];
    [savedImage setScale:0.28*2*(SCREEN_SCALE)];
    [savedImage setAnchorPoint:ccp(0,0)];
    [savedImage setPosition:ccp(24.25*0.28, 24.25*0.28)];
    CCSprite *backing = [CCSprite spriteWithSpriteFrameName:@"blueprints_loadGlow_1.png"];
    [backing setScale:0.28*2*(SCREEN_SCALE)];
    CCSprite *backingSel = [CCSprite spriteWithSpriteFrameName:@"blueprints_loadGlow_sel_1.png"];
    [backingSel setScale:0.28*2*(SCREEN_SCALE)];
    button = [CCMenuItemSprite itemWithNormalSprite:backing selectedSprite:backingSel disabledSprite:nil target:self selector:@selector(expandView)];
    [button addChild:savedImage];
    [button setAnchorPoint:ccp(0, 0)];
    [button  setPosition:ccp((-[button boundingBox].size.width/2)*0.28*2*(SCREEN_SCALE), (-[button boundingBox].size.height/2)*0.28*2*(SCREEN_SCALE))];
    [self addChild:button];
    [self setOpacity:0];
    [self setupButtons];
}

-(void)setupButtons
{
    CCSprite *dbtn = [CCSprite spriteWithSpriteFrameName:@"blueprints_selectDelete_1.png"];
    CCSprite *dbtnsel = [CCSprite spriteWithSpriteFrameName:@"blueprints_selectDelete_sel_1.png"];
    CCSprite *sbtn = [CCSprite spriteWithSpriteFrameName:@"blueprints_selectConfirm_1.png"];
    CCSprite *sbtnsel = [CCSprite spriteWithSpriteFrameName:@"blueprints_selectConfirm_sel_1.png"];
    deleteButton = [CCMenuItemSprite itemWithNormalSprite:dbtn selectedSprite:dbtnsel target:self selector:@selector(deleteCart)];
    saveButton = [CCMenuItemSprite itemWithNormalSprite:sbtn selectedSprite:sbtnsel target:self selector:@selector(loadCart)];
    [saveButton setAnchorPoint:ccp(0, 0)];
    [deleteButton setAnchorPoint:ccp(0, 0)];
    [saveButton setPosition:ccp(-71.75, -53.50)];
    [deleteButton setPosition:ccp(36.75, -53.50)];
    [deleteButton setScale:0.33*2*(SCREEN_SCALE)];
    [saveButton setScale:0.33*2*(SCREEN_SCALE)];
    [saveButton setOpacity:0];
    [deleteButton setOpacity:0];
    [deleteButton setIsEnabled:NO];
    [saveButton setIsEnabled:NO];
    [self addChild:deleteButton];
    [self addChild:saveButton];
}

-(void)minimize
{
    [[self saveDelegate] minimizeSelected];
    [self collapseView];
}

-(void)expandView
{
    if (isExpanded) {return;}
    isExpanded = YES;
    //[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:YES];
    [self setTouchEnabled:YES];
    [saveDelegate expandViewSelected:self];
    CCScaleTo *scale = [CCScaleTo actionWithDuration:0.3 scale:3];
    CCMoveBy *move = [CCMoveBy actionWithDuration:0.3 position:ccp(0, -300)];
    CCSpawn *spawn = [CCSpawn actions:scale, move, nil];
    id seq = [CCSequence actions:spawn, [CCCallFunc actionWithTarget:self selector:@selector(expandComplete)],nil];
    [self runAction:seq];
}

-(void)expandComplete
{
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:255];
    [deleteButton runAction:[[fade copy]autorelease]];
    [saveButton runAction:fade];
    [deleteButton setIsEnabled:YES];
    [saveButton setIsEnabled:YES]; 
    [saveDelegate expandViewComplete];
}

-(void)collapseView
{
    [deleteButton setIsEnabled:NO];
    [saveButton setIsEnabled:NO];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:0];
    [deleteButton runAction:[[fade copy]autorelease]];
    [saveButton runAction:fade];
    CCScaleTo *scale = [CCScaleTo actionWithDuration:0.3 scale:1];
    CCMoveBy *move = [CCMoveBy actionWithDuration:0.3 position:ccp(0, 300)];
    CCSpawn *spawn = [CCSpawn actions:scale, move, nil];
    id seq = [CCSequence actions:spawn, [CCCallFunc actionWithTarget:self selector:@selector(colapseComplete)], nil];
    [self runAction:seq];
}

-(void)colapseComplete
{
//    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:NO];
    [self setTouchEnabled:YES];
    [button setIsEnabled:YES];
    isExpanded = NO;
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(void)saveCart
{
    if ([[SaveManager sharedManager] numberOfSavedCarts] >= 50)
    {
        [ToolTipMenu displayWithMessage:@"You have reached the limit.\n\nDelete one to continue." plankCount:6];
        return;
    }
    [self dissable];
    [saveDelegate cartSaveSelected];
}

-(void)deleteCart
{
    [self setTouchEnabled:NO];
    [saveDelegate dissableAllMenuItems];
    [[SaveManager sharedManager] deleteCartAtIndex:index];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.3f opacity:0];
    [self runAction:[CCSequence actions:fade, [CCCallFunc actionWithTarget:self selector:@selector(deleteReady)],nil]];
}

-(void)deleteReady
{
    [saveDelegate deleteCartSelected:index];
}

-(void)loadCart
{
    [self collapseView];
    [[SaveManager sharedManager] loadCartAtIndex:index];
    [saveDelegate loadCartSelected];
}

-(void)enable
{
    [button setIsEnabled:YES];
}

-(void)dissable
{
    [button setIsEnabled:NO];
}

-(void)setOpacity:(GLubyte)opacity
{
    [savedImage setOpacity:opacity];
    [button setOpacity:opacity];
    [super setOpacity:opacity];
    [saveButton setOpacity:0];
    [deleteButton setOpacity:0];
}

-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:NO]; 
}

@end
