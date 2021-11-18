//
//  SaveMenuItem.h
//  rover
//
//  Created by David Campbell on 5/30/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"

@protocol saveCartMenuItemDelegate <NSObject>
-(void)cartSaveSelected;
-(void)loadCartSelected;
-(void)deleteCartSelected:(int)index;
-(void)expandViewSelected:(id)item;
-(void)expandViewComplete;
-(void)minimizeSelected;
-(void)dissableAllMenuItems;
-(void)enableAllMenuItems;
@end

@interface SaveMenuItem : CCMenu
{
    CCSprite *savedImage;
    CCMenuItemSprite *button;
    CCMenuItemSprite *deleteButton;
    CCMenuItemSprite *saveButton;
    BOOL isExpanded;
}
@property(nonatomic, assign) id<saveCartMenuItemDelegate> saveDelegate;
@property (readwrite) int index;
-(id)initWithImage:(UIImage*)image andIndex:(int)index;
-(id)initAsSaveItem;
-(void)dissable;
-(void)enable;
-(void)collapseView;
-(void)minimize;
@end
