//
//  ToolTipMenu.h
//  rover
//
//  Created by David Campbell on 6/18/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Constants.h"
#import "cocos2d.h"

@interface ToolTipMenu : CCLayer
{
    CCMenu *menu;
    CCSprite *top;
    CCSprite *bottom;
    ToolType toolType;
    CCSprite *background;
    CCSprite *backgroundBacking;
    CCMenuItemToggle *checkBox;
    CCLabelAtlas *text;
    BOOL isClosing;
    BOOL checkState;
    float commonY;
    float offsetY;
    int plankCount;
    NSMutableArray *plankArray;
    NSMutableArray *partArray;
    NSString *contentString;
}
+(void)displayTipForTool:(ToolType)type;
+(void)displayWithMessage:(NSString*)string plankCount:(int)planks;
@end
