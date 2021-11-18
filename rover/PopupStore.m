//
//  PopupStore.m
//  rover
//
//  Created by David Campbell on 7/16/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupStore.h"
#import "ToolTipMenu.h"
#import "Reachability.h"
#import "SaveManager.h"

@implementation PopupStore

-(void)requestStoreItems
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        double delayInSeconds = 0.7;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [ToolTipMenu displayWithMessage:@"No internet connection available." plankCount:10];
        });
    }else
    {
        NSSet *idSet = [NSSet setWithObjects:PRODUCT_BOOST_50, PRODUCT_MOTOR_50,nil];
        productReq = [[SKProductsRequest alloc] initWithProductIdentifiers:idSet];
        [productReq setDelegate:self];
        [productReq start];
    }
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in [response products])
    {
        if ([[product productIdentifier] isEqualToString:PRODUCT_BOOST_50])
        {
            if (![[SaveManager sharedManager] hasBooster50Unlocked])
            {
                [boosterImage runAction:[CCFadeTo actionWithDuration:0.1 opacity:255]];
                boosterLabel = [self setupButton:boostUpgradeBtn forProduct:product];
                [boosterLabel setPosition:ccp(358-[boosterLabel boundingBox].size.width/2.0f, -118)];
                boosterProduct = [product retain];
            }
        }else if ([[product productIdentifier] isEqualToString:PRODUCT_MOTOR_50])
        {
            if (![[SaveManager sharedManager] hasMotor50Unlocked])
            {
                [motorImage runAction:[CCFadeTo actionWithDuration:0.1 opacity:255]];
                [motorHubImage runAction:[CCFadeTo actionWithDuration:0.1 opacity:255]];
                wheelLabel = [self setupButton:wheelUpgradeBtn forProduct:product];
                [wheelLabel setPosition:ccp(358-[wheelLabel boundingBox].size.width/2.0f, 43)];
                wheelProduct = [product retain];
            }
        }
    }
    
    if (![[response products] count])
    {
        [ToolTipMenu displayWithMessage:@"Cannot connect to iTunes Store" plankCount:10];
    }
    
    [productReq release];
    productReq = nil;
}

-(CCLabelAtlas*)setupButton:(CCMenuItemSprite*)button forProduct:(SKProduct*)product
{
    CCNode *parent = [[[self nodeArray] objectAtIndex:0] parent];
    [button runAction:[CCFadeTo actionWithDuration:0.1 opacity:255]];
    [button setIsEnabled:YES];
    NSString *price = [self priceAsString:[product price] locale:[product priceLocale]];
    CCLabelAtlas *priceLabel = [self labelWithText:price];
    [priceLabel setScale:SCREEN_SCALE];
    [parent addChild:priceLabel];
    [[self nodeArray] addObject:priceLabel];

    [priceLabel setOpacity:0];
    [priceLabel runAction:[CCFadeTo actionWithDuration:0.1 opacity:255]];
    
    return priceLabel;
}

-(void)createMenu
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    isMakingPayment = NO;
    
    CCMenuItemImage *logo = [CCMenuItemImage itemWithNormalImage:@"shopLogo.png" selectedImage:@"shopLogo.png"];
    CCMenuItemImage *adNote = [CCMenuItemImage itemWithNormalImage:@"adNote.png" selectedImage:@"adNote.png"];
    CCSprite *wheelUpgrade1 = [CCSprite spriteWithFile:@"wheelUpgrade_1.png"];
    CCSprite *wheelUpgrade2 = [CCSprite spriteWithFile:@"wheelUpgrade_2.png"];
    CCSprite *wheelUpgrade3 = [CCSprite spriteWithFile:@"wheelUpgrade_3.png"];
    CCSprite *boostUpgrade1 = [CCSprite spriteWithFile:@"boostUpgrade_1.png"];
    CCSprite *boostUpgrade2 = [CCSprite spriteWithFile:@"boostUpgrade_2.png"];
    CCSprite *boostUpgrade3 = [CCSprite spriteWithFile:@"boostUpgrade_3.png"];
    CCSprite *restore1 = [CCSprite spriteWithFile:@"restore1.png"];
    CCSprite *restore2 = [CCSprite spriteWithFile:@"restore2.png"];
    
    wheelUpgradeBtn = [CCMenuItemSprite itemWithNormalSprite:wheelUpgrade1 selectedSprite:wheelUpgrade2 disabledSprite:wheelUpgrade3 target:self selector:@selector(wheelUpgradeSelected)];
    if (![[SaveManager sharedManager] hasMotor50Unlocked])
    {
        [wheelUpgradeBtn setOpacity:0];
    }
    [wheelUpgradeBtn setIsEnabled:NO];
    
    boostUpgradeBtn = [CCMenuItemSprite itemWithNormalSprite:boostUpgrade1 selectedSprite:boostUpgrade2 disabledSprite:boostUpgrade3 target:self selector:@selector(boostUpgradeSelected)];
    if (![[SaveManager sharedManager] hasBooster50Unlocked])
    {
        [boostUpgradeBtn setOpacity:0];
    }
    [boostUpgradeBtn setIsEnabled:NO];
    
    CCMenuItemSprite *restoreBtn = [CCMenuItemSprite itemWithNormalSprite:restore1 selectedSprite:restore2 disabledSprite:nil target:self selector:@selector(restorePurchases)];
    
    [boostUpgradeBtn setScale:2*SCREEN_SCALE];
    [wheelUpgradeBtn setScale:2*(SCREEN_SCALE)];
    [logo setScale:2*SCREEN_SCALE];
    [adNote setScale:2*SCREEN_SCALE];
    [restoreBtn setScale:2*SCREEN_SCALE];
    
    [adNote setIsEnabled:NO];
    [logo setIsEnabled:NO];
    
    [wheelUpgradeBtn setPosition:ccp(121.5, 88.5)];
    [boostUpgradeBtn setPosition:ccp(121.5, -72.5)];
    [restoreBtn setPosition:ccp(-274.5, -31)];
    [logo setPosition:ccp(-274.5, 88.5)];
    [adNote setPosition:ccp(-274.5, -120.5)];
    
    CCMenu *menu = [CCMenu menuWithItems:wheelUpgradeBtn, boostUpgradeBtn, restoreBtn, logo, adNote, nil];
    [self createBoosterSpriteOnMenu:menu];
    [self createMotorSpriteOnMenu:menu];
    [menu setPosition:ccp(0, 0)];
    
    [[self nodeArray] addObject:menu];
    [self requestStoreItems];
}

-(void)wheelUpgradeSelected
{
    if (isMakingPayment) {return;}
    isMakingPayment = YES;
    
    if (![SKPaymentQueue canMakePayments])
    {
        [ToolTipMenu displayWithMessage:@"You must enable payments in your device settings." plankCount:5];
    }else
    {
        SKPayment *payment = [SKPayment paymentWithProduct:wheelProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

-(void)boostUpgradeSelected
{
    if (isMakingPayment) {return;}
    isMakingPayment = YES;
    
    if (![SKPaymentQueue canMakePayments])
    {
        [ToolTipMenu displayWithMessage:@"You must enable payments in your device settings." plankCount:5];
    }else
    {
        SKPayment *payment = [SKPayment paymentWithProduct:boosterProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    [self processTransactions:transactions];
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self processTransactions:[queue transactions]];
}

-(void)processTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        if([transaction transactionState] == SKPaymentTransactionStatePurchased
           || [transaction transactionState] == SKPaymentTransactionStateRestored)
        {            
            if ([[[transaction payment] productIdentifier] isEqualToString:PRODUCT_BOOST_50])
            {
                [[SaveManager sharedManager] setHasBooster50Unlocked:YES];
                [boostUpgradeBtn setIsEnabled:NO];
                [boosterLabel setOpacity:0];
            }else if ([[[transaction payment] productIdentifier] isEqualToString:PRODUCT_MOTOR_50])
            {
                [[SaveManager sharedManager] setHasMotor50Unlocked:YES];
                [wheelUpgradeBtn setIsEnabled:NO];
                [wheelLabel setOpacity:0];
            }
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:[[transaction payment] productIdentifier] forKey:@"ProductID"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PURCHASED_ITEM object:nil userInfo:userInfo];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            isMakingPayment = NO;
        }
        else if([transaction transactionState] == SKPaymentTransactionStateFailed)
        {
            if ([[transaction error] code] != SKErrorPaymentCancelled)
            {
                [ToolTipMenu displayWithMessage:[[transaction error] localizedDescription] plankCount:10];
            }
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            isMakingPayment = NO;
        }
    }
}

-(void)restorePurchases
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(int)numberOfPlanks
{
    return 20;
}

- (NSString *)priceAsString:(NSDecimalNumber*)price locale:(NSLocale*)priceLocale
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:priceLocale];
    
    NSString *str = [formatter stringFromNumber:price];
    [formatter release];
    return str;
}

-(id)labelWithText:(NSString*)someText
{
    float factor = 4*SCREEN_SCALE;
    if (SCREEN_SCALE == 1)
    {
        factor = 1;
    }
    return [CCLabelBMFont labelWithString:someText fntFile:@"fontBlk.fnt" width:500*factor alignment:kCCTextAlignmentLeft];
}

-(void)createMotorSpriteOnMenu:(CCMenu*)menu
{
    GameObject *motorSprite = [[GameObject alloc] init];
    [motorSprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTireUpgrade.png"]];
    CCAnimation *animation = [motorSprite loadPlistForAnimationWithName:@"pulse" andClassName:@"wheelUpgrade"];
    CCSprite *motorHubSprite = [[CCSprite alloc] init];
    id repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:animation]];
    [motorHubSprite runAction:repeat];
    
    motorHubImage = [CCMenuItemImage itemWithNormalSprite:motorHubSprite selectedSprite:nil];
    motorImage = [CCMenuItemImage itemWithNormalSprite:motorSprite selectedSprite:nil];
    [motorHubImage setIsEnabled:NO];
    [motorImage setIsEnabled:NO];
    [motorHubImage setPosition:ccp(-50-105.45f/2.0f, 88.5-105.45f/2.0f)];
    [motorImage setPosition:ccp(-50, 88.5)];
    [motorImage setScale:0.30];
    [motorHubImage setScale:0.30];
    
    if (![[SaveManager sharedManager] hasMotor50Unlocked])
    {
        [motorImage setOpacity:0];
        [motorHubImage setOpacity:0];
    }
    [menu addChild:motorImage z:100];
    [menu addChild:motorHubImage z:101];
    [motorSprite release];
    [motorHubSprite release];
}

-(void)createBoosterSpriteOnMenu:(CCMenu*)menu
{
    GameObject *boosterSprite = [[GameObject alloc] init];
    CCAnimation *animation = [boosterSprite loadPlistForAnimationWithName:@"pulse" andClassName:@"boosterUpgrade"];
    id repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:animation]];
    [boosterSprite runAction:repeat];
    
    boosterImage = [CCMenuItemImage itemWithNormalSprite:boosterSprite selectedSprite:nil];
    [boosterImage setIsEnabled:NO];
    [boosterImage setPosition:ccp(-50-102.0f/2.0f, -72.5-68/2.0f)];
    
    if (![[SaveManager sharedManager] hasBooster50Unlocked])
    {
        [boosterImage setOpacity:0];
    }
    [menu addChild:boosterImage z:100];
    [boosterSprite release];
}

-(void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [productReq setDelegate:nil];
    [productReq release];
    productReq = nil;
    [wheelProduct release];
    wheelProduct = nil;
    [boosterProduct release];
    boosterProduct = nil;
    
    [super dealloc];
}

@end
