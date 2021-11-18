//
//  LevelSelectMenuItem.h
//  rover
//
//  Created by David Campbell on 6/17/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"

@protocol LevelSelectMenuItemDelegate <NSObject>
-(void)loadLevelSelected:(int)levelNum;
@end

@interface LevelSelectMenuItem : CCMenu
{
    CCMenuItemSprite *button;
    CCLabelAtlas *numLabel;
    CCLabelAtlas *scoreLabel;
    BOOL isUnlocked;
}
@property (readwrite) int levelNum;
@property (readwrite) int planetNum;
-(id)initWithState:(BOOL)state andLevelNum:(int)indx planetNum:(int)planet;
@property(nonatomic, assign) id<LevelSelectMenuItemDelegate> delegate;
-(void)enable;
-(void)dissable;
@end
