//
//  TitleScene.m
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "TitleScene.h"
#import "Constants.h"
#import "GameManager.h"
#import "PopupMenu.h"
#import "AppDelegate.h"

@implementation TitleScene
-(id)init
{
    if (self = [super init])
    {
        [[GameManager sharedGameManager] stopBackgroundMusic];
        [self setupImages];
    }
    return self;
}

- (void)setupImages
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"MainMenuAtlas.plist"];
    
    CCLayer *layer = [[CCLayer alloc] init];
    [layer setPosition:ccp(0, 0)];
    [self addChild:layer];
    [layer release];
    
#ifdef PROJECTPEON_MAC
    CCSprite *background = [CCSprite spriteWithFile:@"titleBackdropWide.png"];
    [background setScaleY:768.0/background.contentSize.height];
    [background setScaleX:(1024.0*4/3)/background.contentSize.width];
#else
    CCSprite *background = [CCSprite spriteWithFile:@"titleBackdrop.png"];
#endif
#ifndef PROJECTPEON_MAC
    [background setScale:2*SCREEN_SCALE];
#endif
    [background setPosition: ccp(512.0, 384.0)];
    [layer addChild:background];
    
    CCSprite *info = [CCSprite spriteWithFile:@"titleInfo_1.png"];
    CCSprite *infoSel = [CCSprite spriteWithFile:@"titleInfo_2.png"];
    CCSprite *play = [CCSprite spriteWithFile:@"titlePlay_1.png"];
    CCSprite *playSel = [CCSprite spriteWithFile:@"titlePlay_2.png"];
    CCSprite *settings = [CCSprite spriteWithFile:@"titleSettings_1.png"];
    CCSprite *settingsSel = [CCSprite spriteWithFile:@"titleSettings_2.png"];
    
    CCMenuItemSprite *infoBtn = [CCMenuItemSprite itemWithNormalSprite:info selectedSprite:infoSel disabledSprite:nil target:self selector:@selector(openInfoMenu)];
    CCMenuItemSprite *playBtn = [CCMenuItemSprite itemWithNormalSprite:play selectedSprite:playSel disabledSprite:nil target:self selector:@selector(goToMainMenu)];
    CCMenuItemSprite *settingsBtn = [CCMenuItemSprite itemWithNormalSprite:settings selectedSprite:settingsSel disabledSprite:nil target:self selector:@selector(openSettingsMenu)];
    
    [infoBtn setScale:2*SCREEN_SCALE];
    [playBtn setScale:2*SCREEN_SCALE];
    [settingsBtn setScale:2*SCREEN_SCALE];
    
    [infoBtn setPosition:ccp(352, 216)];
    [playBtn setPosition:ccp(512, 216)];
    [settingsBtn setPosition:ccp(672, 216)];
    
    CCMenu *menu = [CCMenu menuWithItems:infoBtn, playBtn, settingsBtn, nil];
    [menu setPosition:ccp(0, 0)];
    [layer addChild:menu];
    
    CCLabelAtlas *text = [self labelWithText:@"Copyright 2013 Digital Fury\nAll rights reserved"];
    [text setPosition:ccp(512, 50)];
    [text setScale:SCREEN_SCALE];
    [layer addChild:text];
}

-(void)goToMainMenu
{
    [[GameManager sharedGameManager] playSoundEffect:@"levelSelect.mp3"];
    [[GameManager sharedGameManager] runSceneWithName:MainMenuSceneID];
}

-(void)openInfoMenu
{
    [PopupMenu showPopupMenuType:kPopupGameInfo withDelegate:self];
}

-(void)openSettingsMenu
{
    [PopupMenu showPopupMenuType:kPopupTitleSettings withDelegate:self];
}

-(id)labelWithText:(NSString*)someText
{
    float factor = 4*SCREEN_SCALE;
    if (SCREEN_SCALE == 1)
    {
        factor = 1;
    }
    return [CCLabelBMFont labelWithString:someText fntFile:@"font42.fnt" width:500*factor alignment:kCCTextAlignmentCenter];
}

-(void)popupDidDismiss:(PopupType)type
{
    //Do nothing
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setMovieController:nil];
    [self setMovieTapHandler:nil];
    [super dealloc];
}

@end
