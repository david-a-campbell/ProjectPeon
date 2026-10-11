//
//  PopupCartCreation.m
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupCartCreation.h"
#import "SaveManager.h"
#import "GameManager.h"
#ifdef PROJECTPEON_IOS
#import "BaseGameScene.h"
#import "PopupMenu.h"
#import "PeonVolumeSettings.h"
#endif

@implementation PopupCartCreation

-(void)createMenu
{
    checkState = [[SaveManager sharedManager] getShowToolTipsState];
    
    CCSprite *levelSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_levelSelect_1.png"];
    CCSprite *levelSelSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_levelSelect_2.png"];
    CCSprite *settings = [CCSprite spriteWithSpriteFrameName:@"menu_btn_settings_1.png"];
    CCSprite *settingsSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_settings_sel_1.png"];
    CCSprite *returnToTitle = [CCSprite spriteWithSpriteFrameName:@"menu_btn_returnToTitle_1.png"];
    CCSprite *returnToTitleSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_returnToTitle_sel_1.png"];
    CCMenuItemImage *on = [CCMenuItemImage itemWithNormalImage:@"checkbox_2.png" selectedImage:@"checkbox_2.png"];
    CCMenuItemImage *off = [CCMenuItemImage itemWithNormalImage:@"checkbox_1.png" selectedImage:@"checkbox_1.png"];
    
    if (checkState)
    {
        checkBox = [CCMenuItemToggle itemWithTarget:self selector:@selector(checkStateChange) items:on, off, nil];
    }else
    {
        checkBox = [CCMenuItemToggle itemWithTarget:self selector:@selector(checkStateChange) items:off, on, nil];
    }
    
    CCMenuItemSprite *levelSelBtn = [CCMenuItemSprite itemWithNormalSprite:levelSel selectedSprite:levelSelSel disabledSprite:nil target:self selector:@selector(returnToLevelSelect)];
    
    CCMenuItemSprite *settingsBtn = [CCMenuItemSprite itemWithNormalSprite:settings selectedSprite:settingsSel disabledSprite:nil target:[self popupDelegate] selector:@selector(goToSettings)];
    
    CCMenuItemSprite *returnToTitleBtn = [CCMenuItemSprite itemWithNormalSprite:returnToTitle selectedSprite:returnToTitleSel disabledSprite:nil target:[self popupDelegate] selector:@selector(returnToTitle)];
    
    [levelSelBtn setScale:2*SCREEN_SCALE];
    [settingsBtn setScale:2*(SCREEN_SCALE)];
    [returnToTitleBtn setScale:2*(SCREEN_SCALE)];
    [checkBox setScale:2*SCREEN_SCALE];
    
#ifdef PROJECTPEON_IOS
    BaseGameScene *scene=(id)[CCDirector sharedDirector].runningScene;
    BOOL panning=[scene isKindOfClass:[BaseGameScene class]] && scene.debugFreePanEnabled;
    BOOL showPan=![scene isKindOfClass:[BaseGameScene class]] || ![scene cartSaveMenuOpen];
    NSMutableArray *items=[NSMutableArray arrayWithObjects:levelSelBtn,settingsBtn,returnToTitleBtn,nil];
    if (showPan) {
        CCLabelBMFont *label=[CCLabelBMFont labelWithString:panning ? @"return to building" : @"pan camera" fntFile:@"font52.fnt"];
        PeonInsetBitmapGlyphs(label); label.scale=SCREEN_SCALE;
        CCMenuItemLabel *pan=[CCMenuItemLabel itemWithLabel:label target:self selector:@selector(panCamera)];
        pan.contentSize=returnToTitleBtn.boundingBox.size;
        label.anchorPoint=ccp(.5,.5); label.position=ccp(pan.contentSize.width/2,pan.contentSize.height/2);
        [pan addChild:PeonSettingsTextGlow(label) z:-1];
        [items addObject:pan];
    }
    [items addObject:checkBox];
    CCMenu *menu=[CCMenu menuWithArray:items];
#else
    CCMenu *menu=[CCMenu menuWithItems:levelSelBtn,settingsBtn,returnToTitleBtn,checkBox,nil];
#endif
    [menu alignItemsVerticallyWithPadding: 0];
    [menu setPosition:ccp(0, 0)];
    [[self nodeArray] addObject:menu];
}

#ifdef PROJECTPEON_IOS
-(void)panCamera
{
    BaseGameScene *scene=(id)[CCDirector sharedDirector].runningScene;
    if (![scene isKindOfClass:[BaseGameScene class]] || [scene cartSaveMenuOpen]) return;
    [(PopupMenu *)self.popupDelegate hide];
    // Wait for the popup's closing animation so modal input blocking still applies.
    [scene performSelector:@selector(toggleCartCreationPan) withObject:nil afterDelay:.3];
}
#endif

-(void)returnToLevelSelect
{
    [[GameManager sharedGameManager] setLoadCurrentPlanetByDefault:YES];
    [[self popupDelegate] returnToLevelSelect];
}

-(void)checkStateChange
{
    checkState = !checkState;
    [[SaveManager sharedManager] setShowToolTipsState:checkState];
}

-(void)checkStateChangeTut
{
    checkStateTut = !checkStateTut;
    [[SaveManager sharedManager] setShowTutorialState:checkStateTut];
}

-(int)numberOfPlanks
{
#ifdef PROJECTPEON_IOS
    BaseGameScene *scene=(id)[CCDirector sharedDirector].runningScene;
    if (![scene isKindOfClass:[BaseGameScene class]] || ![scene cartSaveMenuOpen]) return 30;
#endif
    return 24;
}

@end
