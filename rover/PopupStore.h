//
//  PopupStore.h
//  rover
//
//  Created by David Campbell on 7/16/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "BasePopupMenu.h"
#import "GameObject.h"

@interface PopupStore : BasePopupMenu
{
    CCMenuItemSprite *wheelUpgradeBtn;
    CCMenuItemSprite *boostUpgradeBtn;
    
    CCMenuItemImage *motorImage;
    CCMenuItemImage *motorHubImage;
    CCMenuItemImage *boosterImage;
}
@end
