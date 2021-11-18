//
//  PopupStore.h
//  rover
//
//  Created by David Campbell on 7/16/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "BasePopupMenu.h"
#import "GameObject.h"
#import <StoreKit/StoreKit.h>

@interface PopupStore : BasePopupMenu <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    SKProductsRequest *productReq;
    CCMenuItemSprite *wheelUpgradeBtn;
    CCMenuItemSprite *boostUpgradeBtn;
    SKProduct *wheelProduct;
    SKProduct *boosterProduct;
    CCLabelAtlas *boosterLabel;
    CCLabelAtlas *wheelLabel;
    BOOL isMakingPayment;
    
    CCMenuItemImage *motorImage;
    CCMenuItemImage *motorHubImage;
    CCMenuItemImage *boosterImage;
}
@end
