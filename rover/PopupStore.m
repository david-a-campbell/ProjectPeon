//
//  PopupStore.m
//  rover
//
//  Created by David Campbell on 7/16/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupStore.h"
#import "ToolTipMenu.h"
#import "SaveManager.h"
#import "../mac/PeonBitmapFont.h"

@implementation PopupStore

-(void)createMenu
{
    
    CCMenuItemImage *logo = [CCMenuItemImage itemWithNormalImage:@"shopLogo.png" selectedImage:@"shopLogo.png"];
    CCMenuItemImage *adNote = [CCMenuItemImage itemWithNormalImage:@"adNote.png" selectedImage:@"adNote.png"];
    CCSprite *wheelUpgrade1 = [CCSprite spriteWithFile:@"wheelUpgrade_1.png"];
    CCSprite *wheelUpgrade2 = [CCSprite spriteWithFile:@"wheelUpgrade_2.png"];
    CCSprite *wheelUpgrade3 = [CCSprite spriteWithFile:@"wheelUpgrade_3.png"];
    CCSprite *boostUpgrade1 = [CCSprite spriteWithFile:@"boostUpgrade_1.png"];
    CCSprite *boostUpgrade2 = [CCSprite spriteWithFile:@"boostUpgrade_2.png"];
    CCSprite *boostUpgrade3 = [CCSprite spriteWithFile:@"boostUpgrade_3.png"];
    CCSprite *restore1 = [CCSprite spriteWithFile:@"restore1.png"];
    CCSprite *restore2 = [CCSprite spriteWithFile:@"restore2.png"];
    
    wheelUpgradeBtn = [CCMenuItemSprite itemWithNormalSprite:wheelUpgrade1 selectedSprite:wheelUpgrade2 disabledSprite:wheelUpgrade3 target:self selector:@selector(wheelUpgradeSelected)];
    if (![[SaveManager sharedManager] hasMotor50Unlocked])
    {
        [wheelUpgradeBtn setOpacity:0];
    }
    [wheelUpgradeBtn setIsEnabled:NO];
    
    boostUpgradeBtn = [CCMenuItemSprite itemWithNormalSprite:boostUpgrade1 selectedSprite:boostUpgrade2 disabledSprite:boostUpgrade3 target:self selector:@selector(boostUpgradeSelected)];
    if (![[SaveManager sharedManager] hasBooster50Unlocked])
    {
        [boostUpgradeBtn setOpacity:0];
    }
    [boostUpgradeBtn setIsEnabled:NO];
    
    CCMenuItemSprite *restoreBtn = [CCMenuItemSprite itemWithNormalSprite:restore1 selectedSprite:restore2 disabledSprite:nil target:self selector:@selector(restorePurchases)];
    
    [boostUpgradeBtn setScale:2*SCREEN_SCALE];
    [wheelUpgradeBtn setScale:2*(SCREEN_SCALE)];
    [logo setScale:2*SCREEN_SCALE];
    [adNote setScale:2*SCREEN_SCALE];
    [restoreBtn setScale:2*SCREEN_SCALE];
    
    [adNote setIsEnabled:NO];
    [logo setIsEnabled:NO];
    
    [wheelUpgradeBtn setPosition:ccp(121.5, 88.5)];
    [boostUpgradeBtn setPosition:ccp(121.5, -72.5)];
    [restoreBtn setPosition:ccp(-274.5, -31)];
    [logo setPosition:ccp(-274.5, 88.5)];
    [adNote setPosition:ccp(-274.5, -120.5)];
    
    CCMenu *menu = [CCMenu menuWithItems:wheelUpgradeBtn, boostUpgradeBtn, restoreBtn, logo, adNote, nil];
    [self createBoosterSpriteOnMenu:menu];
    [self createMotorSpriteOnMenu:menu];
    [menu setPosition:ccp(0, 0)];
    
    [restoreBtn setVisible:NO]; [restoreBtn setIsEnabled:NO];
    [adNote setVisible:NO];
    CCLabelBMFont *included = [CCLabelBMFont labelWithString:@"All upgrades\nincluded" fntFile:@"font42.fnt"];
    included.alignment = kCCTextAlignmentCenter;
    PeonInsetBitmapGlyphs(included);
    included.scale = SCREEN_SCALE * 0.85;
    included.position = ccp(-274.5, -25);
    [[self nodeArray] addObject:included];
    CCLabelBMFont *purchases = [CCLabelBMFont labelWithString:@"No purchases\nrequired" fntFile:@"font42.fnt"];
    purchases.alignment = kCCTextAlignmentCenter;
    PeonInsetBitmapGlyphs(purchases);
    purchases.scale = SCREEN_SCALE * 0.85;
    purchases.position = ccp(-274.5, -105);
    [[self nodeArray] addObject:purchases];
    [[self nodeArray] addObject:menu];
}

// Upgrade cards are informational: all upgrades are included offline.
-(void)wheelUpgradeSelected {}
-(void)boostUpgradeSelected {}
-(void)restorePurchases {}

-(int)numberOfPlanks
{
    return 20;
}

-(void)createMotorSpriteOnMenu:(CCMenu*)menu
{
    GameObject *motorSprite = [[GameObject alloc] init];
    [motorSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTireUpgrade.png"]];
    CCAnimation *animation = [motorSprite loadPlistForAnimationWithName:@"pulse" andClassName:@"wheelUpgrade"];
    CCSprite *motorHubSprite = [[CCSprite alloc] init];
    id repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:animation]];
    [motorHubSprite runAction:repeat];
    
    motorHubImage = [CCMenuItemImage itemWithNormalSprite:motorHubSprite selectedSprite:nil];
    motorImage = [CCMenuItemImage itemWithNormalSprite:motorSprite selectedSprite:nil];
    [motorHubImage setIsEnabled:NO];
    [motorImage setIsEnabled:NO];
    [motorHubImage setPosition:ccp(-50-105.45f/2.0f, 88.5-105.45f/2.0f)];
    [motorImage setPosition:ccp(-50, 88.5)];
    [motorImage setScale:0.30];
    [motorHubImage setScale:0.30];
    
    if (![[SaveManager sharedManager] hasMotor50Unlocked])
    {
        [motorImage setOpacity:0];
        [motorHubImage setOpacity:0];
    }
    [menu addChild:motorImage z:100];
    [menu addChild:motorHubImage z:101];
    [motorSprite release];
    [motorHubSprite release];
}

-(void)createBoosterSpriteOnMenu:(CCMenu*)menu
{
    GameObject *boosterSprite = [[GameObject alloc] init];
    CCAnimation *animation = [boosterSprite loadPlistForAnimationWithName:@"pulse" andClassName:@"boosterUpgrade"];
    id repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:animation]];
    [boosterSprite runAction:repeat];
    
    boosterImage = [CCMenuItemImage itemWithNormalSprite:boosterSprite selectedSprite:nil];
    [boosterImage setIsEnabled:NO];
    [boosterImage setPosition:ccp(-50-102.0f/2.0f, -72.5-68/2.0f)];
    
    if (![[SaveManager sharedManager] hasBooster50Unlocked])
    {
        [boosterImage setOpacity:0];
    }
    [menu addChild:boosterImage z:100];
    [boosterSprite release];
}

@end
