//
//  PopupMainMenu.m
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupLevelSelect.h"

@implementation PopupLevelSelect

-(void)createMenu
{
    CCSprite *settings = [CCSprite spriteWithSpriteFrameName:@"menu_btn_settings_1.png"];
    CCSprite *settingsSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_settings_sel_1.png"];
    CCSprite *returnToTitle = [CCSprite spriteWithSpriteFrameName:@"menu_btn_returnToTitle_1.png"];
    CCSprite *returnToTitleSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_returnToTitle_sel_1.png"];
    CCSprite *tutorial = [CCSprite spriteWithSpriteFrameName:@"menu_btn_tutorial_1.png"];
    CCSprite *tutorialSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_tutorial_sel_1.png"];
    
    CCMenuItemSprite *settingsBtn = [CCMenuItemSprite itemWithNormalSprite:settings selectedSprite:settingsSel disabledSprite:nil target:[self popupDelegate] selector:@selector(goToSettings)];
    
    CCMenuItemSprite *returnToTitleBtn = [CCMenuItemSprite itemWithNormalSprite:returnToTitle selectedSprite:returnToTitleSel disabledSprite:nil target:[self popupDelegate] selector:@selector(returnToTitle)];
    
    CCMenuItemSprite *tutorialBtn = [CCMenuItemSprite itemWithNormalSprite:tutorial selectedSprite:tutorialSel disabledSprite:nil target:[self popupDelegate] selector:@selector(showTutorial)];
    
    [settingsBtn setScale:2*(SCREEN_SCALE)];
    [returnToTitleBtn setScale:2*(SCREEN_SCALE)];
    [tutorialBtn setScale:2*SCREEN_SCALE];
    
    CCMenu *menu = [CCMenu menuWithItems:settingsBtn, tutorialBtn, returnToTitleBtn, nil];
    [menu alignItemsVerticallyWithPadding: 0];
    [menu setPosition:ccp(0, 0)];
    [[self nodeArray] addObject:menu];
}

-(int)numberOfPlanks
{
    return 18;
}
@end
