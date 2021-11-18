//
//  PopupGamePlay.m
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupGamePlay.h"
#import "GameManager.h"
#import "LevelSelectMenu.h"

@implementation PopupGamePlay

-(void)createMenu
{
    CCSprite *video = [CCSprite spriteWithSpriteFrameName:@"menu_btn_shareVideo_1.png"];
    CCSprite *videSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_shareVideo_2.png"];
    CCSprite *levelSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_levelSelect_1.png"];
    CCSprite *levelSelSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_levelSelect_2.png"];
    CCSprite *settings = [CCSprite spriteWithSpriteFrameName:@"menu_btn_settings_1.png"];
    CCSprite *settingsSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_settings_sel_1.png"];
    CCSprite *returnToTitle = [CCSprite spriteWithSpriteFrameName:@"menu_btn_returnToTitle_1.png"];
    CCSprite *returnToTitleSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_returnToTitle_sel_1.png"];
    CCSprite *relaunch = [CCSprite spriteWithSpriteFrameName:@"menu_btn_relaunch_1.png"];
    CCSprite *relaunchSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_relaunch_sel_1.png"];
    CCSprite *cartCreation = [CCSprite spriteWithSpriteFrameName:@"menu_btn_cartCreation_1.png"];
    CCSprite *cartCreationSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_cartCreation_sel_1.png"];
    
    CCMenuItemSprite *videoBtn = [CCMenuItemSprite itemWithNormalSprite:video selectedSprite:videSel disabledSprite:nil target:self selector:@selector(showVideoMenu)];
    
    CCMenuItemSprite *levelSelBtn = [CCMenuItemSprite itemWithNormalSprite:levelSel selectedSprite:levelSelSel disabledSprite:nil target:self selector:@selector(returnToLevelSelect)];
    
    CCMenuItemSprite *relaunchBtn = [CCMenuItemSprite itemWithNormalSprite:relaunch selectedSprite:relaunchSel disabledSprite:nil target:[self popupDelegate] selector:@selector(relaunch)];

    CCMenuItemSprite *cartCreationBtn = [CCMenuItemSprite itemWithNormalSprite:cartCreation selectedSprite:cartCreationSel disabledSprite:nil target:[self popupDelegate] selector:@selector(goToCartCreation)];
    
    CCMenuItemSprite *settingsBtn = [CCMenuItemSprite itemWithNormalSprite:settings selectedSprite:settingsSel disabledSprite:nil target:[self popupDelegate] selector:@selector(goToSettings)];
    
    CCMenuItemSprite *returnToTitleBtn = [CCMenuItemSprite itemWithNormalSprite:returnToTitle selectedSprite:returnToTitleSel disabledSprite:nil target:[self popupDelegate] selector:@selector(returnToTitle)];
    
    [videoBtn setScale:2*SCREEN_SCALE];
    [settingsBtn setScale:2*(SCREEN_SCALE)];
    [returnToTitleBtn setScale:2*(SCREEN_SCALE)];
    [relaunchBtn setScale:2*SCREEN_SCALE];
    [cartCreationBtn setScale:2*SCREEN_SCALE];
    [levelSelBtn setScale:2*SCREEN_SCALE];
    
    CCMenu *menu = [CCMenu menuWithItems:relaunchBtn, cartCreationBtn, levelSelBtn, videoBtn, settingsBtn, returnToTitleBtn, nil];
    [menu alignItemsVerticallyWithPadding: 0];
    [menu setPosition:ccp(0, 0)];
    [[self nodeArray] addObject:menu];
}

-(void)showVideoMenu
{

}

-(void)returnToLevelSelect
{
    [[GameManager sharedGameManager] setLoadCurrentPlanetByDefault:YES];
    [[self popupDelegate] returnToLevelSelect];
}

-(int)numberOfPlanks
{
    return 31;
}

@end
