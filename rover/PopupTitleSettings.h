//
//  PopupTitleSettings.h
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "BasePopupMenu.h"

@interface PopupTitleSettings : BasePopupMenu
{
    BOOL retinaOn;
    BOOL forGameplay;
    CCMenuItemToggle *retinaSwitch;
    CCMenuItemSprite *controlTiltBtn;
    CCMenuItemSprite *controlTouchBtn;
}
-(id)initWithDelegate:(id<popupMenuDelegate>)delegate forGameplay:(BOOL)gameplay;
@end
