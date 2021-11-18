//
//  LevelSelectMenu.h
//  rover
//
//  Created by David Campbell on 6/17/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "SWScrollView.h"
#import "LevelSelectMenuItem.h"
#import "PopupMenu.h"

@protocol levelMenuDelegate <NSObject>
-(void)planetSelected:(int)planetNum;

@end

@interface LevelSelectMenu : CCLayer <SWScrollViewDelegate, LevelSelectMenuItemDelegate , popupMenuDelegate>
{
    SWScrollView *scrollview;
    NSMutableArray *menuItemList;
    int currentPlanet;
    BOOL menuItemsEnabled;
    BOOL didScroll;
    CCMenuItemSprite *nextPlanet;
    CCMenuItemSprite *prevPlanet;
    CCMenu* planetSelectMenu;
    CCMenu *tabMenu;
    CCMenuItemSprite *tabMenuSprite;
}
@property(nonatomic, assign) id<levelMenuDelegate> delegate;
-(void)configureForPlanetNumber:(int)planetNum;
-(id)initWithPlanetNum:(int)planetToLoad;
@end
