//
//  SaveMenu.h
//  rover
//
//  Created by David Campbell on 5/30/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "SaveMenuItem.h"
#import "SWScrollView.h"

@protocol saveMenuDelegate
-(void)saveMenuDidDismiss;
-(void)saveCartSelected;
-(void)saveCartComplete;
-(void)deleteItemSelected;
-(void)deleteItemComplete;
@optional
-(void)loadCartSelected;
@end

@interface SaveMenu : CCLayer <saveCartMenuItemDelegate, SWScrollViewDelegate>
{
    CCSprite *blueprints_background;
    CCSprite *blueprints_left_1;
    CCSprite *blueprints_left_2;
    CCSprite *blueprints_right_1;
    CCSprite *blueprints_right_2;
    NSMutableArray *saveMenuItemList;
    SWScrollView *scrollview;
    BOOL menuItemsEnabled;
    SaveMenuItem *expandedItem;
    BOOL isSaving;
    BOOL didScroll;
}
@property (readonly) BOOL isMenuDisplaying;
@property(nonatomic, assign) id<saveMenuDelegate> delegate;
-(void)showMenu;
-(void)dissmissMenu;
-(void)setOpacity:(GLubyte)opacity;
-(void)runAction:(CCAction*)action;
-(void)setIsMenuEnabled:(BOOL)isTouchEnabled;
-(void)cancelSave;
@end
