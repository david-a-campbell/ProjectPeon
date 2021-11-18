//
//  PopupGameInfo.m
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupGameInfo.h"
#import "GameManager.h"

@implementation PopupGameInfo

-(void)createMenu
{
    CCSprite *text = [self labelWithText:@"Credits\n\nDesign: Daniel Campbell\nProgramming: David Campbell\nAudio: Juan Sajche\n\nSpecial Thanks\n\nPavan Aila\nNathan Baker\nCrage Campbell\nMike Close\nJesse Frye\nMichael Huang\nRobert Michel\nLevar Morris\nDwight Peters\nJosef Salyer\nMadhen Venkataraman\nOmar Walker\n"];
    [text setScale:SCREEN_SCALE];
    [text setPosition:ccp(0, 40)];
    
    CCSprite *website = [CCSprite spriteWithFile:@"url_1.png"];
    CCSprite *websiteSel = [CCSprite spriteWithFile:@"url_2.png"];
    CCMenuItemSprite *websiteBtn = [CCMenuItemSprite itemWithNormalSprite:website selectedSprite:websiteSel disabledSprite:nil target:self selector:@selector(openGameWebsite)];

    [websiteBtn setScale:2*(SCREEN_SCALE)];
    CCMenu *menu = [CCMenu menuWithItems: websiteBtn, nil];
    [menu alignItemsVerticallyWithPadding: 0];
    [menu setPosition:ccp(0, -230)];
    [[self nodeArray] addObject:menu];
    [[self nodeArray] addObject:text];
}

-(void)openGameWebsite
{
    [[GameManager sharedGameManager] openSiteWithLinkType:kLinkTypeGameSite];
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

-(int)numberOfPlanks
{
    return 32;
}

@end
