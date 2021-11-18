//
//  popupMenu.h
//  rover
//
//  Created by David Campbell on 5/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "PopupLevelSelect.h"
#import "Constants.h"

@interface PopupMenu : CCLayer <popupMenuDelegate>
{
    CCSprite *top;
    CCSprite *bottom;
    
    CCSprite *overlay;
    CCSprite *backOverlay;
    CCParticleSystem *menuParticles;
    BasePopupMenu *currentOptions;
    PopupType type;
    NSMutableArray *plankArray;
    NSMutableArray *menuStack;
    CGPoint topOriginalPos;
    CGPoint bottomOriginalPos;
    BOOL isClosing;
    BOOL volumeChanged;
}
@property(nonatomic, assign) id<popupMenuDelegate> popupDelegate;
-(id)initForType:(PopupType)type andDelegate:(id<popupMenuDelegate>) popupDelegate;

+(void)showPopupMenuType:(PopupType)type withDelegate:(id<popupMenuDelegate>) popupDelegate;

@end
