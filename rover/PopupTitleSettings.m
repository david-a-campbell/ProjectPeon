//
//  PopupTitleSettings.m
//  rover
//
//  Created by David Campbell on 6/27/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupTitleSettings.h"
#import "SaveManager.h"
#import "GameManager.h"
#import "ToolTipMenu.h"
#import "CCControlExtension.h"

@implementation PopupTitleSettings

-(id)initWithDelegate:(id<popupMenuDelegate>)delegate forGameplay:(BOOL)gameplay
{
    if (self = [super init])
    {
        [self setNodeArray:[NSMutableArray array]];
        forGameplay = gameplay;
        [self setPopupDelegate:delegate];
        [self createMenu];
    }
    return self;
}

-(void)createMenu
{
    retinaOn = [[SaveManager sharedManager] isRetinaEnabled];
    float musicVolume = [[SaveManager sharedManager] getMusicVolume];
    float sfxVolume = [[SaveManager sharedManager] getSfxVolume];
    
    CCMenuItemImage *retinaSel = [CCMenuItemImage itemWithNormalImage:@"retinaSwitch2.png" selectedImage:@"retinaSwitch2.png"];
    CCMenuItemImage *retina = [CCMenuItemImage itemWithNormalImage:@"retinaSwitch1.png" selectedImage:@"retinaSwitch1.png"];
    CCSprite *controlTilt1 = [CCSprite spriteWithFile:@"controlTilt1.png"];
    CCSprite *controlTilt2 = [CCSprite spriteWithFile:@"controlTilt2.png"];
    CCSprite *controlTilt3 = [CCSprite spriteWithFile:@"controlTilt3.png"];
    CCSprite *controlTouch1 = [CCSprite spriteWithFile:@"controlTouch1.png"];
    CCSprite *controlTouch2 = [CCSprite spriteWithFile:@"controlTouch2.png"];
    CCSprite *controlTouch3 = [CCSprite spriteWithFile:@"controlTouch3.png"];
    CCSprite *tutorial = [CCSprite spriteWithSpriteFrameName:@"menu_btn_tutorial_1.png"];
    CCSprite *tutorialSel = [CCSprite spriteWithSpriteFrameName:@"menu_btn_tutorial_sel_1.png"];
    
    CCControlSlider *musicSlider = [CCControlSlider sliderWithBackgroundFile:@"volumeBlank.png" progressFile:@"volumeBar.png" thumbFile:@"volumeBlank.png"];
    CCControlSlider *sfxSlider = [CCControlSlider sliderWithBackgroundFile:@"volumeBlank.png" progressFile:@"volumeBar.png" thumbFile:@"volumeBlank.png"];
    musicSlider.minimumValue = 0.0f;
    musicSlider.maximumValue = 1.0f;
    sfxSlider.minimumValue = 0.0f;
    sfxSlider.maximumValue = 1.0f;
    [musicSlider setValue:musicVolume];
    [sfxSlider setValue:sfxVolume];
    
    [musicSlider addTarget:self action:@selector(musicValueChanged:) forControlEvents:CCControlEventValueChanged];
    [sfxSlider addTarget:self action:@selector(sfxValueChanged:) forControlEvents:CCControlEventValueChanged];
    
    CCMenuItemImage *sfxVolumeBG = [CCMenuItemImage itemWithNormalImage:@"sfxVolume.png" selectedImage:@"sfxVolume.png"];
    CCMenuItemImage *musicVolumeBG = [CCMenuItemImage itemWithNormalImage:@"musicVolume.png" selectedImage:@"musicVolume.png"];
    CCMenuItemImage *controlSwitchBG = [CCMenuItemImage itemWithNormalImage:@"controlSwitch.png" selectedImage:@"controlSwitch.png"];
    [sfxVolumeBG setIsEnabled:NO];
    [musicVolumeBG setIsEnabled:NO];
    
    if (retinaOn)
    {
        retinaSwitch = [CCMenuItemToggle itemWithTarget:self selector:@selector(switchRetina) items:retinaSel, retina, nil];
    }else
    {
        retinaSwitch = [CCMenuItemToggle itemWithTarget:self selector:@selector(switchRetina) items:retina, retinaSel, nil];
    }
    
    controlTiltBtn = [CCMenuItemSprite itemWithNormalSprite:controlTilt1 selectedSprite:controlTilt2 disabledSprite:controlTilt3 target:self selector:@selector(switchToTiltControl)];
    controlTouchBtn = [CCMenuItemSprite itemWithNormalSprite:controlTouch1 selectedSprite:controlTouch2 disabledSprite:controlTouch3 target:self selector:@selector(switchToTouchControl)];
    
    CCMenuItemSprite *tutorialBtn = [CCMenuItemSprite itemWithNormalSprite:tutorial selectedSprite:tutorialSel disabledSprite:nil target:[self popupDelegate] selector:@selector(showTutorial)];
    
    [musicVolumeBG setScale:2*SCREEN_SCALE];
    [sfxVolumeBG setScale:2*SCREEN_SCALE];
    [musicSlider setScale:2*SCREEN_SCALE];
    [sfxSlider setScale:2*SCREEN_SCALE];
    [tutorialBtn setScale:2*SCREEN_SCALE];
    [controlSwitchBG setScale:2*SCREEN_SCALE];
    [controlTiltBtn setScale:2*SCREEN_SCALE];
    [controlTouchBtn setScale:2*SCREEN_SCALE];
    [retinaSwitch setScale:2*SCREEN_SCALE];
    
    CCMenu *menu;
    if (IS_RETINA)
    {
        menu = [CCMenu menuWithItems:musicVolumeBG, sfxVolumeBG, controlSwitchBG, retinaSwitch, tutorialBtn, nil];
        [musicSlider setPosition:ccp(145, 180)];
        [sfxSlider setPosition:ccp(145, 90)];
        [controlTiltBtn setPosition:ccp(28, 0)];
        [controlTouchBtn setPosition:ccp(188, 0)];
    }else
    {
        menu = [CCMenu menuWithItems:musicVolumeBG, sfxVolumeBG, controlSwitchBG, tutorialBtn, nil];
        [musicSlider setPosition:ccp(145, 135)];
        [sfxSlider setPosition:ccp(145, 45)];
        [controlTiltBtn setPosition:ccp(28, -45)];
        [controlTouchBtn setPosition:ccp(188, -45)];
    }
    
    [menu alignItemsVerticallyWithPadding: 0];
    [menu setPosition:ccp(0, 0)];
    
    CCMenu *subMenu = [CCMenu menuWithItems:controlTiltBtn, controlTouchBtn, nil];
    [subMenu setPosition:ccp(0, 0)];
    
    BOOL useTouch = [[SaveManager sharedManager] useTouchControl];
    [controlTouchBtn setIsEnabled:!useTouch];
    [controlTiltBtn setIsEnabled:useTouch];
    
    [[self nodeArray] addObject:musicSlider];
    [[self nodeArray] addObject:sfxSlider];
    [[self nodeArray] addObject:menu];
    [[self nodeArray] addObject:subMenu];
}

-(void)switchRetina
{
    retinaOn = !retinaOn;
    [[SaveManager sharedManager] setIsRetinaEnabled:retinaOn];
    
    BOOL wasRetinaOn = [[CCDirector sharedDirector] contentScaleFactor] > 1;
    [[GameManager sharedGameManager] setAppNeedsRestart:(wasRetinaOn != retinaOn)];
    
    NSString *restartMessage = (wasRetinaOn!=retinaOn)?@"You must restart the app for this change to take effect.":@"";
    NSString *warningMessage = retinaOn?@"Enabling retina may reduce performance on some devices.":@"";
    
    if ([restartMessage length] && [warningMessage length])
    {
        NSString *finalMessage = [NSString stringWithFormat:@"%@\n\n%@", warningMessage, restartMessage];
        [ToolTipMenu displayWithMessage:finalMessage plankCount:9];
    }else if([warningMessage length])
    {
        [ToolTipMenu displayWithMessage:warningMessage plankCount:5];
    }else if([restartMessage length])
    {
        [ToolTipMenu displayWithMessage:restartMessage plankCount:5];
    }
}

-(void)switchToTiltControl
{
    [controlTiltBtn setIsEnabled:NO];
    [controlTouchBtn setIsEnabled:YES];
    [[SaveManager sharedManager] setUseTouchControl:NO];
}

-(void)switchToTouchControl
{
    [controlTouchBtn setIsEnabled:NO];
    [controlTiltBtn setIsEnabled:YES];
    [[SaveManager sharedManager] setUseTouchControl:YES];
}

-(void)musicValueChanged:(CCControlSlider*)sender
{
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:sender.value];
    [[self popupDelegate] setVolumeChanged];
}

-(void)sfxValueChanged:(CCControlSlider*)sender
{
    [[SimpleAudioEngine sharedEngine] setEffectsVolume:sender.value];
    [[self popupDelegate] setVolumeChanged];
}

-(int)numberOfPlanks
{
    if (!IS_RETINA)
    {
        return 20;
    }
    return 26;
}
@end
