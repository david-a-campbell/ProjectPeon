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
    
    CCSprite *background = [CCSprite spriteWithFile:@"titleBackdrop.png"];
    [background setScale:2*SCREEN_SCALE];
    [background setPosition: ccp(512.0, 384.0)];
    [layer addChild:background];
    
    CCSprite *facebook = [CCSprite spriteWithFile:@"titleFB_1.png"];
    CCSprite *facebookSel = [CCSprite spriteWithFile:@"titleFB_2.png"];
    CCSprite *info = [CCSprite spriteWithFile:@"titleInfo_1.png"];
    CCSprite *infoSel = [CCSprite spriteWithFile:@"titleInfo_2.png"];
    CCSprite *play = [CCSprite spriteWithFile:@"titlePlay_1.png"];
    CCSprite *playSel = [CCSprite spriteWithFile:@"titlePlay_2.png"];
    CCSprite *settings = [CCSprite spriteWithFile:@"titleSettings_1.png"];
    CCSprite *settingsSel = [CCSprite spriteWithFile:@"titleSettings_2.png"];
    CCSprite *twitter = [CCSprite spriteWithFile:@"titleTwitter_1.png"];
    CCSprite *twitterSel = [CCSprite spriteWithFile:@"titleTwitter_2.png"];
    
    CCMenuItemSprite *facebookBtn = [CCMenuItemSprite itemWithNormalSprite:facebook selectedSprite:facebookSel disabledSprite:nil target:self selector:@selector(goToFacebook)];
    CCMenuItemSprite *infoBtn = [CCMenuItemSprite itemWithNormalSprite:info selectedSprite:infoSel disabledSprite:nil target:self selector:@selector(openInfoMenu)];
    CCMenuItemSprite *playBtn = [CCMenuItemSprite itemWithNormalSprite:play selectedSprite:playSel disabledSprite:nil target:self selector:@selector(goToMainMenu)];
    CCMenuItemSprite *settingsBtn = [CCMenuItemSprite itemWithNormalSprite:settings selectedSprite:settingsSel disabledSprite:nil target:self selector:@selector(openSettingsMenu)];
    CCMenuItemSprite *twitterBtn = [CCMenuItemSprite itemWithNormalSprite:twitter selectedSprite:twitterSel disabledSprite:nil target:self selector:@selector(goToTwitter)];
    
    [facebookBtn setScale:2*SCREEN_SCALE];
    [infoBtn setScale:2*SCREEN_SCALE];
    [playBtn setScale:2*SCREEN_SCALE];
    [settingsBtn setScale:2*SCREEN_SCALE];
    [twitterBtn setScale:2*SCREEN_SCALE];
    
    [facebookBtn setPosition:ccp(352, 216)];
    [infoBtn setPosition:ccp(802, 216)];
    [playBtn setPosition:ccp(512, 216)];
    [settingsBtn setPosition:ccp(672, 216)];
    [twitterBtn setPosition:ccp(222, 216)];
    
    CCMenu *menu = [CCMenu menuWithItems:facebookBtn, infoBtn, playBtn, settingsBtn, twitterBtn, nil];
    [menu setPosition:ccp(0, 0)];
    [layer addChild:menu];
    
    CCLabelAtlas *text = [self labelWithText:@"Copyright 2013 Digital Fury\nAll rights reserved"];
    [text setPosition:ccp(512, 50)];
    [text setScale:SCREEN_SCALE];
    [layer addChild:text];
}

-(void)goToFacebook
{
    [[GameManager sharedGameManager] openSiteWithLinkType:kLinkTypeFacebook];
}

-(void)goToTwitter
{
    [[GameManager sharedGameManager] openSiteWithLinkType:kLinkTypeTwitter];
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
