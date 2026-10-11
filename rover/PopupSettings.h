//
//  PopupSettings.h
//  rover
//
//  Created by David Campbell on 6/27/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "BasePopupMenu.h"

@interface PopupSettings : BasePopupMenu
{
    BOOL retinaOn;
    BOOL forGameplay;
    CCMenuItemToggle *retinaSwitch;
    CCMenuItemSprite *controlTiltBtn;
    CCMenuItemSprite *controlTouchBtn;
#ifdef PROJECTPEON_IOS
    CCMenu *controlChoiceMenu;
#endif
}
-(id)initWithDelegate:(id<popupMenuDelegate>)delegate forGameplay:(BOOL)gameplay;
@end
