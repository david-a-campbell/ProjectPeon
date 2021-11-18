//
//  CartCreationLayer.m
//  rover
//
//  Created by David Campbell on 3/6/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartCreationLayer.h"
#import "GameObject.h"
#import "PlayerCart.h"
#import "PopupMenu.h"
#import "GameTimer.h"
#import "SaveManager.h"
#import "FuelGauge.h"
#import "ToolTipMenu.h"
#import "CartPart.h"
#import "ShockImageSet.h"

@interface CartCreationLayer(Private)
-(void)setupTempToolImages;
-(void)createBarEnded;
-(void)createWheelEnded;
-(void)createShockEnded;
-(void)createMotorEnded;
-(void)createMotorStarted;
-(void)createMotorMoved;
-(void)createBoosterStarted;
-(void)createBoosterMoved;
-(void)createBoosterEnded;
-(void)createMenu;
-(void)startGamePlay;
-(void)endGameplay;
@end

@implementation CartCreationLayer
@synthesize saveMenu, levelScoreDisplay;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [tempMotor release];
    tempMotor = nil;
    [tempMotorHub release];
    tempMotorHub = nil;
    [tempMotorHub50 release];
    tempMotorHub50 = nil;
    [tempMotor50 release];
    tempMotor50 = nil;
    [tempBar release];
    tempBar = nil;
    [tempWheel release];
    tempWheel = nil;
    [shockImageSet release];
    shockImageSet = nil;
    [tempBooster release];
    tempBooster = nil;
    [tempBooster50 release];
    tempBooster50 = nil;
    [timer release];
    timer = nil;
    [fuelGauge release];
    fuelGauge = nil;
    [levelScoreDisplay release];
    levelScoreDisplay = nil;
    [editingPart release];
    editingPart = nil;
    [editingShocks release];
    editingShocks = nil;
    [editingShockImages release];
    editingShockImages = nil;
    [super dealloc];
}

-(id)retain
{
    return [super retain];
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(id)initwithLayerToFollow:(CCLayer*)layer andDelegate:(id<cartCreationDelegate>) theDelegate topLayer:(CCLayer *)topLayer
{
    if ((self = [super init])) 
    {
        currentMotorType = toolTypeMotor;
        currentBoosterType = toolTypeBooster;
        if ([[SaveManager sharedManager] hasMotor50Unlocked])
        {
            currentMotorType = toolTypeMotor50;
        }
        if ([[SaveManager sharedManager] hasBooster50Unlocked])
        {
            currentBoosterType = toolTypeBooster50;
        }
        [self scheduleUpdate];
        layerToFollow = layer;
        cartCreationDelegate = theDelegate;
        [self slideToolMenuIn];
        [self setupTempToolImages];
        [self setupTimer];
        [self setupFuelGauge];
        [self setupPopupMenuOnLayer:topLayer];
        [self setupScoreDisplay];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:NOTIFICATION_WILL_RESIGN_ACTIVE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameplayStarted) name:NOTIFICATION_BEGIN_GAMEPLAY object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slideToolMenuIn) name:NOTIFICATION_END_GAMEPLAY object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calculateScore) name:NOTIFICATION_LEVEL_COMPLETE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemPurchased:) name:NOTIFICATION_PURCHASED_ITEM object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWillRotate) name:NOTIFICATION_WILL_ROTATE object:nil];
        [[SaveManager sharedManager] setOffset:[layerToFollow position]];
        [[GameManager sharedGameManager] setIsPaused:NO];
        popupTypeToShow = kPopupTypeCartCreation;
        cartCreationEnabled = YES;
        self.touchEnabled = YES;
    }
    return self;
}

-(void)willResignActive
{
    [self removeAllTempImages];
}

-(void)deviceWillRotate
{
    if (creationTouch)
    {
        [self ccTouchEnded:creationTouch withEvent:nil];
    }
    if (rotateEditTouch)
    {
        [self ccTouchEnded:rotateEditTouch withEvent:nil];
    }
    if (moveEditTouch)
    {
        [self ccTouchEnded:moveEditTouch withEvent:nil];
    }
}

-(void)removeAllTempImages
{
    [self removeChild:tempBar cleanup:YES];
    [self removeChild:tempMotor cleanup:YES];
    [self removeChild:tempMotorHub cleanup:YES];
    [self removeChild:tempMotor50 cleanup:YES];
    [self removeChild:tempMotorHub50 cleanup:YES];
    [self removeChild:[shockImageSet tempShock] cleanup:YES];
    [self removeChild:tempWheel cleanup:YES]; 
    [self removeChild:tempBooster cleanup:YES];
    [self removeChild:tempBooster50 cleanup:YES];
    for(ShockImageSet *set in editingShockImages)
    {
        [self removeChild:[set tempShock] cleanup:YES];
    }
    [editingShockImages removeAllObjects];
}

-(void)setupTimer
{
    timer = [[GameTimer alloc] initAtLocation:ccp(40, 728) withTime:[cartCreationDelegate getMapTime]];
    [self addChild:timer z:9];
}

-(void)setupFuelGauge
{
    fuelGauge = [[FuelGauge alloc] initWithPlayerCart:[cartCreationDelegate getPlayerCart] atPosition:[timer position]];
    [self addChild:fuelGauge z:[timer zOrder]];
}

-(void)setupPopupMenuOnLayer:(CCLayer*)layer
{    
    tabMenuSprite = [CCMenuItemSprite   itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"menu_callTab_1.png"]
                                        selectedSprite:  [CCSprite spriteWithSpriteFrameName:@"menu_callTab_sel_1.png"] 
                                        block:^(id sender) 
                                            {
                                                if ([timer state]!=kStateStopped)
                                                {
                                                    [timer pauseSchedulerAndActions];
                                                }
                                                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                                                [self slideDeleteMenuOut];
                                                [self slideMotorMenuOut];
                                                [self slideDeleteMenuOut];
                                                [PopupMenu showPopupMenuType:popupTypeToShow withDelegate:self];
                                            }];
    [tabMenuSprite setScale:SCREEN_SCALE*2];
    tabMenu = [CCMenu menuWithItems:tabMenuSprite, nil];
    [tabMenu setPosition:ccp(966.5, 735.5)];
    [layer addChild:tabMenu z:1000];
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.1], [CCCallFunc actionWithTarget:self selector:@selector(changeTabMenuPriority)],nil]];
}

-(void)changeTabMenuPriority
{
    [tabMenu setHandlerPriority:-600];
}

-(void)popupDidDismiss:(PopupType)type
{
    if (type == kPopupStore)
    {
        [self selectToolType:toolTypeNone];
    }
    if ([timer state]!=kStateStopped)
    {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        [timer resumeSchedulerAndActions];
    }   
}

-(void)setupScoreDisplay
{
    LevelScoreDisplay *tempDisp = [[LevelScoreDisplay alloc] init];
    [self setLevelScoreDisplay:tempDisp];
    [tempDisp release];
    [tempDisp setDelegate:self];
}

-(void)replayLevelSelected
{
    [self goToCartCreation];
    [tabMenu runAction:[CCFadeTo actionWithDuration:0.5 opacity:255]];
    [tabMenu setTouchEnabled:YES];
}

-(void)saveMenuDidDismiss
{
    [saveMenu removeFromParentAndCleanup:YES];
    saveMenu = nil;
    [self slideToolMenuIn];
}

-(void)showSaveMenu
{
    if (!saveMenu)
    {
        saveMenu = [[SaveMenu alloc] init];
        [[self parent] addChild:saveMenu z:[self zOrder]+1];
        [saveMenu setDelegate:self];
        [saveMenu release];
    }
    [saveMenu showMenu];
}

-(void)setupTempToolImages
{
    tempBooster = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"booster.png"]];
    tempBooster50 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"boosterUpgrade_1.png"]];
    tempMotor = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTire.png"]];
    tempMotor50 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTireUpgrade.png"]];
    tempMotorHub = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelHub.png"]];
    tempMotorHub50 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelHubUpgrade_1.png"]];
    tempBar = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"bar.png"]];
    tempWheel = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"circle.png"]];
    shockImageSet = [[ShockImageSet alloc] init];

    [tempBar setScaleY:1];
    [tempBooster setScale:1];
    [tempBooster50 setScale:1];
    
    tempBarOriginalLength = [tempBar boundingBox].size.width;
    tempWheelOriginalHeight = [tempWheel boundingBox].size.height;
    tempMotorOriginalHeight = [tempMotor boundingBox].size.height;
    
    [tempMotorHub setOpacity:150];
    [tempMotor setOpacity:150];
    [tempMotorHub50 setOpacity:150];
    [tempMotor50 setOpacity:150];
    [tempBar setOpacity:150];
    [tempWheel setOpacity:150];
    [tempBooster setOpacity:150];
    [tempBooster50 setOpacity:150];
    
    [tempMotorHub setPosition:ccp([tempMotor boundingBox].size.width/2, [tempMotor boundingBox].size.height/2)];
    [tempMotorHub50 setPosition:ccp([tempMotor50 boundingBox].size.width/2, [tempMotor50 boundingBox].size.height/2)];

    [tempMotor addChild:tempMotorHub];
    [tempMotor50 addChild:tempMotorHub50];
}

-(void)setupMenuImages
{
    startButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_launch_1.png"];
    startButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_launch_sel_1.png"];
    barButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_bar_1.png"];
    barButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_bar_sel_1.png"];
    barButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_bar_sel_1.png"];
    shockButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_shock_1.png"];
    shockButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_shock_sel_1.png"];
    shockButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_shock_sel_1.png"];
    wheelButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_circle_1.png"];
    wheelButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_circle_sel_1.png"];
    wheelButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_circle_sel_1.png"];
    boosterButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_1.png"];
    boosterButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_sel_1.png"];
    boosterButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_sel_1.png"];
    motorButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_1.png"];
    motorButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_sel_1.png"];
    motorButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_sel_1.png"];
    deleteButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_delete_1.png"];
    deleteButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_delete_sel_1.png"];
    deleteButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_delete_sel_1.png"];
    saveButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_blueprints_1.png"];
    saveButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_blueprints_sel_1.png"];
    saveButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_blueprints_sel_1.png"];
    shopButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_shop_1.png"];
    shopButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_shop_sel_1.png"];
    shopButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_shop_sel_1.png"];
    editButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_edit_1.png"];
    editButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_edit_sel_1.png"];
    editButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_edit_sel_1.png"];
}

-(void)createDeleteAllMenu
{
    CCSprite *deleteAllButton = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_deleteAll_1.png"];
    CCSprite *deleteAllButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_deleteAll_2.png"];
    CCSprite *deleteAllButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_deleteAll_2.png"];
    
    deleteAllBtnSprite = [CCMenuItemSprite itemWithNormalSprite:deleteAllButton selectedSprite:deleteAllButtonSel disabledSprite:deleteAllButtonDis block:^(id sender){
        [cartCreationDelegate deleteAllCartParts];
        [deleteSubMenu runAction:[self slideIn:NO toPosition:deleteAllMenuDown]];
        isDeleteAllMenuUp = NO;
    } touchBlock:nil];
    
    [deleteAllBtnSprite setScale:2*SCREEN_SCALE];
    CCMenuItemImage *deleteAllBacking = [CCMenuItemImage itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"popup.png"] selectedSprite:nil];
    [deleteAllBacking setScale:2*SCREEN_SCALE];
    [deleteAllBacking setIsEnabled:NO];
    
    deleteSubMenu = [CCMenu menuWithItems:deleteAllBtnSprite, nil];
    [deleteSubMenu addChild:deleteAllBacking z:-10];
    deleteAllMenuUp = ccp(876, 165);
    deleteAllMenuDown = ccp(876, -65);
    [deleteSubMenu setPosition:deleteAllMenuDown];
    [self addChild:deleteSubMenu z:999];
    
    isDeleteAllMenuUp = NO;
}

-(void)createMotorMenu
{
    CCSprite *motor50Button = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_1.png"];
    CCSprite *motor50ButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_sel_1.png"];
    CCSprite *motor50ButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_sel_1.png"];
    
    motor50BtnSprite = [CCMenuItemSprite itemWithNormalSprite:motor50Button selectedSprite:motor50ButtonSel disabledSprite:motor50ButtonDis block:^(id sender)
    {
        if ([[SaveManager sharedManager] hasMotor50Unlocked])
        {
            if (currentMotorType == toolTypeMotor)
            {
                [self switchToMotorType:toolTypeMotor50];
            }else
            {
                [self switchToMotorType:toolTypeMotor];
            }
        }else
        {
            [PopupMenu showPopupMenuType:kPopupStore withDelegate:self];            
        }
        [self slideMotorMenuOut];
    } touchBlock:nil];
    
    [motor50BtnSprite setScale:2*SCREEN_SCALE];
    CCMenuItemImage *motorMenuBacking = [CCMenuItemImage itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"popup.png"] selectedSprite:nil];
    [motorMenuBacking setScale:2*SCREEN_SCALE];
    [motorMenuBacking setIsEnabled:NO];
    
    motorSubMenu = [CCMenu menuWithItems:motor50BtnSprite, nil];
    [motorSubMenu addChild:motorMenuBacking z:-10];
    motorMenuUp = ccp(372, 165);
    motorMenuDown = ccp(372, -65);
    [motorSubMenu setPosition:motorMenuDown];
    [self addChild:motorSubMenu z:999];
    
    isMotorMenuUp = NO;
}

-(void)switchToMotorType:(ToolType)type
{
    currentMotorType = type;
    switch (currentMotorType)
    {
        case toolTypeMotor50:
        {
            currentMotorType = toolTypeMotor50;
            [motor50BtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_1.png"]];
            [motor50BtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_sel_1.png"]];
            [motor50BtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_sel_1.png"]];
            
            [motorBtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_1.png"]];
            [motorBtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_sel_1.png"]];
            [motorBtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_sel_1.png"]];
            break;
        }
        case toolTypeMotor:
        {
            currentMotorType = toolTypeMotor;
            [motorBtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_1.png"]];
            [motorBtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_sel_1.png"]];
            [motorBtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheel_sel_1.png"]];
            
            [motor50BtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_1.png"]];
            [motor50BtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_sel_1.png"]];
            [motor50BtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_wheelUpgrade_sel_1.png"]];
            break;
        }
        default:
            break;
    }
    [self selectToolType:currentMotorType];
    [motorBtnSprite selected];
}

-(void)createBoosterMenu
{
    CCSprite *booster50Button = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_1.png"];
    CCSprite *booster50ButtonSel = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_sel_1.png"];
    CCSprite *booster50ButtonDis = [CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_sel_1.png"];
    
    booster50BtnSprite = [CCMenuItemSprite itemWithNormalSprite:booster50Button selectedSprite:booster50ButtonSel disabledSprite:booster50ButtonDis block:^(id sender)
    {
        if ([[SaveManager sharedManager] hasBooster50Unlocked])
        {
            if (currentBoosterType == toolTypeBooster)
            {
                [self switchToBoosterType:toolTypeBooster50];
            }else
            {
                [self switchToBoosterType:toolTypeBooster];
            }
        }else
        {
            [PopupMenu showPopupMenuType:kPopupStore withDelegate:self];
        }
        [self slideBoosterMenuOut];
    } touchBlock:nil];
    
    [booster50BtnSprite setScale:2*SCREEN_SCALE];
    CCMenuItemImage *boosterMenuBacking = [CCMenuItemImage itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"popup.png"] selectedSprite:nil];
    [boosterMenuBacking setScale:2*SCREEN_SCALE];
    [boosterMenuBacking setIsEnabled:NO];
    
    boosterSubMenu = [CCMenu menuWithItems:booster50BtnSprite, nil];
    [boosterSubMenu addChild:boosterMenuBacking z:-10];
    boosterMenuUp = ccp(270, 165);
    boosterMenuDown = ccp(270, -65);
    [boosterSubMenu setPosition:boosterMenuDown];
    [self addChild:boosterSubMenu z:999];
    
    isBoosterMenuUp = NO;
}

-(void)switchToBoosterType:(ToolType)type
{
    currentBoosterType = type;
    switch (currentBoosterType)
    {
        case toolTypeBooster50:
        {
            currentBoosterType = toolTypeBooster50;
            [booster50BtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_1.png"]];
            [booster50BtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_sel_1.png"]];
            [booster50BtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_sel_1.png"]];
            
            [boosterBtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_1.png"]];
            [boosterBtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_sel_1.png"]];
            [boosterBtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_sel_1.png"]];
            break;
        }
        case toolTypeBooster:
        {
            currentBoosterType = toolTypeBooster;
            [boosterBtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_1.png"]];
            [boosterBtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_sel_1.png"]];
            [boosterBtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_booster_sel_1.png"]];
            
            [booster50BtnSprite setNormalImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_1.png"]];
            [booster50BtnSprite setDisabledImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_sel_1.png"]];
            [booster50BtnSprite setSelectedImage:[CCSprite spriteWithSpriteFrameName:@"createMenu_btn_boosterUpgrade_sel_1.png"]];
            break;
        }
        default:
            break;
    }
    [self selectToolType:currentBoosterType];
    [boosterBtnSprite selected];
}

-(void)createMenu
{
    [self setupMenuImages];
    float commonY = 49.473f;
    
    startBtnSprite = [CCMenuItemSprite itemWithNormalSprite:startButton selectedSprite:startButtonSel disabledSprite:nil target:self selector:@selector(startGameplay)];
    [startBtnSprite setPosition:ccp(967, commonY)];
    [startBtnSprite setScale:SCREEN_SCALE*2];
    //
    barBtnSprite = [CCMenuItemSprite itemWithNormalSprite:barButton selectedSprite:barButtonSel disabledSprite:barButtonDis 
                                                                                                block:^(id sender) {
                                                                                                [ToolTipMenu displayTipForTool:toolTypeBar];
                                                                                                [self selectToolType:toolTypeBar];
                                                                                                [barBtnSprite selected];
                                                                                                [barBtnSprite setIsEnabled:NO];
                                                                                                } touchBlock:nil];
    [barBtnSprite setPosition:ccp(568, commonY)];
    [barBtnSprite setScale:SCREEN_SCALE*2];
    //
    shockBtnSprite = [CCMenuItemSprite itemWithNormalSprite:shockButton selectedSprite:shockButtonSel disabledSprite:shockButtonDis
                                                                                                block:^(id sender) {
                                                                                                    [ToolTipMenu displayTipForTool:toolTypeShock];
                                                                                                    [self selectToolType:toolTypeShock];
                                                                                                    [shockBtnSprite selected];
                                                                                                    [shockBtnSprite setIsEnabled:NO];
                                                                                                } touchBlock:nil];
    [shockBtnSprite setPosition:ccp(468, commonY)];
    [shockBtnSprite setScale:SCREEN_SCALE*2];
    //
    wheelBtnSprite = [CCMenuItemSprite itemWithNormalSprite:wheelButton selectedSprite:wheelButtonSel disabledSprite:wheelButtonDis 
                                                                                              block:^(id sender) {
                                                                                                  [ToolTipMenu displayTipForTool:toolTypeWheel];
                                                                                                  [self selectToolType:toolTypeWheel];
                                                                                                  [wheelBtnSprite selected];
                                                                                                  [wheelBtnSprite setIsEnabled:NO];
                                                                                              } touchBlock:nil];
    [wheelBtnSprite setPosition:ccp(668, commonY)];
    [wheelBtnSprite setScale:SCREEN_SCALE*2];
    //
    
    TouchBlock boosterTblock = ^(id sender){
        longPressType = toolTypeBooster;
        if (isBoosterMenuUp)
        {
            [self slideBoosterMenuOut];
            return;
        }
        [self schedule:@selector(longPress:)];
        longPressCounter = 0;
    };
    boosterBtnSprite = [CCMenuItemSprite itemWithNormalSprite:boosterButton selectedSprite:boosterButtonSel disabledSprite:boosterButtonDis
                                                                                              block:^(id sender) {
                                                                                                  if (selectedTool != toolTypeBooster
                                                                                                      && selectedTool != toolTypeBooster50)
                                                                                                  {
                                                                                                      [ToolTipMenu displayTipForTool:toolTypeBooster];
                                                                                                  }
                                                                                                  [self unschedule:@selector(longPress:)];
                                                                                                  [self selectToolType:toolTypeBooster];
                                                                                                  [boosterBtnSprite selected];
                                                                                              } touchBlock:boosterTblock];
    [boosterBtnSprite setPosition:ccp(270, commonY)];
    [boosterBtnSprite setScale:SCREEN_SCALE*2];
    //
    
    TouchBlock motorTblock = ^(id sender){
        longPressType = toolTypeMotor;
        if (isMotorMenuUp)
        {
            [self slideMotorMenuOut];
            return;
        }
        [self schedule:@selector(longPress:)];
        longPressCounter = 0;
    };
    motorBtnSprite = [CCMenuItemSprite itemWithNormalSprite:motorButton selectedSprite:motorButtonSel disabledSprite:motorButtonDis
                                                                                              block:^(id sender) {
                                                                                                  if (selectedTool != toolTypeMotor50
                                                                                                      && selectedTool != toolTypeMotor)
                                                                                                  {
                                                                                                    [ToolTipMenu displayTipForTool:toolTypeMotor];
                                                                                                  }
                                                                                                  [self unschedule:@selector(longPress:)];
                                                                                                  [self selectToolType:toolTypeMotor];
                                                                                                  [motorBtnSprite selected];
                                                                                              } touchBlock:motorTblock];
    [motorBtnSprite setPosition:ccp(372, commonY)];
    [motorBtnSprite setScale:SCREEN_SCALE*2];
    //
    
    TouchBlock deleteTblock = ^(id sender){
        longPressType = toolTypeDelete;
        if (isDeleteAllMenuUp)
        {
            [self slideDeleteMenuOut];
            return;
        }
        [self schedule:@selector(longPress:)];
        longPressCounter = 0;
    };
    deleteBtnSprite = [CCMenuItemSprite itemWithNormalSprite:deleteButton selectedSprite:deleteButtonSel disabledSprite:deleteButtonDis 
                                                                                              block:^(id sender){
                                                                                                  if(selectedTool != toolTypeDelete) {[ToolTipMenu displayTipForTool:toolTypeDelete];}
                                                                                                  [self unschedule:@selector(longPress:)];
                                                                                                  [self selectToolType:toolTypeDelete];
                                                                                                  [deleteBtnSprite selected];
                                                                                                }
                                                                                                touchBlock:deleteTblock];
    
    [deleteBtnSprite setPosition:ccp(876 , commonY)];
    [deleteBtnSprite setScale:SCREEN_SCALE*2];
    //
    saveBtnSprite = [CCMenuItemSprite itemWithNormalSprite:saveButton selectedSprite:saveButtonSel disabledSprite:saveButtonDis
                                                       block:^(id sender) {
                                                           [saveBtnSprite selected];
                                                           [self selectToolType:toolTypeSave];
                                                           [self showSaveMenu];
                                                           [self hideToolMenu];
                                                           [saveBtnSprite setIsEnabled:NO];
                                                       } touchBlock:nil];
    [saveBtnSprite setPosition:ccp(157 , commonY)];
    [saveBtnSprite setScale:SCREEN_SCALE*2];
    //
    shopBtnSprite = [CCMenuItemSprite itemWithNormalSprite:shopButton selectedSprite:shopButtonSel disabledSprite:shopButtonDis
                                                     block:^(id sender) {
                                                         [shopBtnSprite selected];
                                                         [self selectToolType:toolTypeShop];
                                                         [PopupMenu showPopupMenuType:kPopupStore withDelegate:self];
                                                         [shopBtnSprite setIsEnabled:NO];
                                                     } touchBlock:nil];
    [shopBtnSprite setPosition:ccp(62 , commonY)];
    [shopBtnSprite setScale:SCREEN_SCALE*2];
    //
    editBtnSprite = [CCMenuItemSprite itemWithNormalSprite:editButton selectedSprite:editButtonSel disabledSprite:editButtonDis block:^(id sender) {
        [ToolTipMenu displayTipForTool:toolTypeEdit];
        [self selectToolType:toolTypeEdit];
        [editBtnSprite selected];
        [editBtnSprite setIsEnabled:NO];
    } touchBlock:nil];
    [editBtnSprite setPosition:ccp(784, commonY)];
    [editBtnSprite setScale:SCREEN_SCALE*2];
    
    toolMenu = [CCMenu menuWithItems:shopBtnSprite, startBtnSprite, barBtnSprite, wheelBtnSprite, shockBtnSprite, motorBtnSprite, boosterBtnSprite, deleteBtnSprite, saveBtnSprite, editBtnSprite, nil];
    
    createMenuBackground = [CCMenuItemImage itemWithNormalImage:@"createMenu_body.png" selectedImage:nil];
    [createMenuBackground setScale:SCREEN_SCALE*2];
    [createMenuBackground setAnchorPoint:ccp(0,0)];
    [createMenuBackground setIsEnabled:NO];
    
    CCMenuItemImage *popupUpArrowDelete = [CCMenuItemImage itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"popupArrow_up.png"] selectedSprite:nil];
    [popupUpArrowDelete setScale:SCREEN_SCALE];
    [popupUpArrowDelete setIsEnabled:NO];
    [popupUpArrowDelete setPosition:ccp(876, 91.5)];
    
    CCMenuItemImage *popupUpArrowMotor = [CCMenuItemImage itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"popupArrow_up.png"] selectedSprite:nil];
    [popupUpArrowMotor setScale:SCREEN_SCALE];
    [popupUpArrowMotor setIsEnabled:NO];
    [popupUpArrowMotor setPosition:ccp(372, 91.5)];
    
    CCMenuItemImage *popupUpArrowBooster = [CCMenuItemImage itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"popupArrow_up.png"] selectedSprite:nil];
    [popupUpArrowBooster setScale:SCREEN_SCALE];
    [popupUpArrowBooster setIsEnabled:NO];
    [popupUpArrowBooster setPosition:ccp(270, 91.5)];
    
    [toolMenu addChild:createMenuBackground z:-10];
    [toolMenu addChild:popupUpArrowDelete z:-9];
    [toolMenu addChild:popupUpArrowMotor z:-9];
    [toolMenu addChild:popupUpArrowBooster z:-9];
    
    toolMenuUp = ccp(0.0 , 0.0);
    toolMenuDown = ccp(0.0, -100.0);
    
    [toolMenu setAnchorPoint:ccp(0,0)];
    [toolMenu setPosition:toolMenuDown];
    [self addChild:toolMenu z:1000];
    [toolMenu setTouchEnabled:NO];
    
    [self switchToMotorType:currentMotorType];
    [self switchToBoosterType:currentBoosterType];
    [self selectToolType:toolTypeNone];
}

-(void)longPress:(ccTime)dt
{
    if (longPressCounter >= 1)
    {
        [self unschedule:@selector(longPress:)];
        switch (longPressType)
        {
            case toolTypeDelete:
                [self slideDeleteMenuIn];
                [self slideMotorMenuOut];
                [self slideBoosterMenuOut];
                break;
            case toolTypeMotor:
                [self slideMotorMenuIn];
                [self slideDeleteMenuOut];
                [self slideBoosterMenuOut];
                break;
            case toolTypeBooster:
                [self slideBoosterMenuIn];
                [self slideDeleteMenuOut];
                [self slideMotorMenuOut];
            default:
                break;
        }
    }
    longPressCounter+=0.05;
}

-(id)slideIn:(BOOL)in toPosition:(CGPoint)position
{
    id moveAction = [CCMoveTo actionWithDuration:0.3f position:position];
    id moveEffect;
    if(in)
        moveEffect = [CCEaseIn actionWithAction:moveAction rate:0.2];
    else
        moveEffect = [CCEaseOut actionWithAction:moveAction rate:0.2];
    return moveEffect;
}

-(void)slideDeleteMenuOut
{
    if (isDeleteAllMenuUp)
    {
        [deleteSubMenu runAction:[self slideIn:NO toPosition:deleteAllMenuDown]];
        isDeleteAllMenuUp = NO;
        [cartCreationDelegate unhighlightCart];
    }
}

-(void)slideMotorMenuOut
{
    if (isMotorMenuUp)
    {
        [motorSubMenu runAction:[self slideIn:NO toPosition:motorMenuDown]];
        isMotorMenuUp = NO;
    }
}

-(void)slideBoosterMenuOut
{
    if (isBoosterMenuUp)
    {
        [boosterSubMenu runAction:[self slideIn:NO toPosition:boosterMenuDown]];
        isBoosterMenuUp = NO;
    }
}

-(void)slideDeleteMenuIn
{
    if (!isDeleteAllMenuUp)
    {
        [deleteSubMenu runAction:[self slideIn:YES toPosition:deleteAllMenuUp]];
        isDeleteAllMenuUp = YES;
        [cartCreationDelegate highlightCart];
    }
}

-(void)slideMotorMenuIn
{
    if (!isMotorMenuUp)
    {
        [motorSubMenu runAction:[self slideIn:YES toPosition:motorMenuUp]];
        isMotorMenuUp = YES;
    }
}

-(void)slideBoosterMenuIn
{
    if (!isBoosterMenuUp)
    {
        [boosterSubMenu runAction:[self slideIn:YES toPosition:boosterMenuUp]];
        isBoosterMenuUp = YES;
    }
}

-(void)startGameplay
{    
    if (![cartCreationDelegate cartHasParts])
    {
        [ToolTipMenu displayWithMessage:@"Your cart must have parts!" plankCount:4];
        return;
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self hideToolMenu];
    [fuelGauge fadeIn];
    [cartCreationDelegate startAction];
    popupTypeToShow = kPopupTypeGamePlay;
}

-(void)slideToolMenuIn
{
    if (!deleteSubMenu)
    {
        [self createDeleteAllMenu];
    }
    if (!motorSubMenu)
    {
        [self createMotorMenu];
    }
    if(!boosterSubMenu)
    {
        [self createBoosterMenu];
    }
    if (!toolMenu)
    {
        [self createMenu]; 
    }
    [toolMenu runAction:[self slideIn:YES toPosition:toolMenuUp]];
    [self activateCreationMenu];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
}

-(void)hideToolMenu
{
    [self slideDeleteMenuOut];
    [self slideMotorMenuOut];
    [self slideBoosterMenuOut];
    cartCreationEnabled = NO;
    [toolMenu setTouchEnabled:NO];
    id sequence = [CCSequence actions:[self slideIn:NO toPosition:toolMenuDown], [CCCallFunc actionWithTarget:self selector:@selector(removeToolMenu)],nil];
    [toolMenu runAction:sequence];
}

-(void)removeToolMenu
{
    [toolMenu removeFromParentAndCleanup:YES];
    toolMenu = nil;
    [deleteSubMenu removeFromParentAndCleanup:YES];
    deleteSubMenu = nil;
    [motorSubMenu removeFromParentAndCleanup:YES];
    motorSubMenu = nil;
    [boosterSubMenu removeFromParentAndCleanup:YES];
    boosterSubMenu = nil;
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
}

-(void)gameplayStarted
{
    [timer startTimer];
}

-(void)relaunch
{
    [timer resetTimer];
    [fuelGauge fadeIn];
    [cartCreationDelegate resetAction];
}

-(void)goToCartCreation
{
    if (!cartCreationEnabled) {
        [self endGameplay];
    }
}

-(void)endGameplay
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [cartCreationDelegate stopAction];
    [timer resetTimer];
    [fuelGauge fadeOut];
    popupTypeToShow = kPopupTypeCartCreation;
}

-(void)activateCreationMenu
{
    cartCreationEnabled = YES;
    [toolMenu setTouchEnabled:YES];
}

-(void)enableAllMenuButtons
{
    [startBtnSprite setIsEnabled:YES];
    [saveBtnSprite setIsEnabled:YES];
    [self enableAllCreationMenuButtons];
}

-(void)enableAllCreationMenuButtons
{
    [barBtnSprite setIsEnabled:YES];
    [wheelBtnSprite setIsEnabled:YES];
    [shockBtnSprite setIsEnabled:YES];
    [motorBtnSprite setIsEnabled:YES];
    [boosterBtnSprite setIsEnabled:YES];
    [deleteBtnSprite setIsEnabled:YES];
    [shopBtnSprite setIsEnabled:YES];
    [editBtnSprite setIsEnabled:YES];
}

-(void)dissableAllMenuButtons
{
    [startBtnSprite setIsEnabled:NO];
    [barBtnSprite setIsEnabled:NO];
    [wheelBtnSprite setIsEnabled:NO];
    [shockBtnSprite setIsEnabled:NO];
    [motorBtnSprite setIsEnabled:NO];
    [boosterBtnSprite setIsEnabled:NO];
    [deleteBtnSprite setIsEnabled:NO];
    [saveBtnSprite setIsEnabled:NO];
    [shopBtnSprite setIsEnabled:NO];
    [editBtnSprite setIsEnabled:NO];
}

- (void)registerWithTouchDispatcher 
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:2 swallowsTouches:YES];
}

-(BOOL)shouldAllowCartCreation
{    
    return (cartCreationEnabled && ![[GameManager sharedGameManager] isPaused]);
}

-(BOOL)touchIsValidForCreation:(CGPoint)touchLocation
{
    if (touchLocation.y >= GroundHeight && touchLocation.y <=768 && touchLocation.x >= 0 && touchLocation.x <= 1024)
    {
        return YES;
    }
    return NO;
}

-(CGPoint)makeTouchValidForCreation:(CGPoint)touchLocation
{
    CGPoint validLocation = touchLocation;
    if (touchLocation.y < GroundHeight)
    {
        validLocation.y = GroundHeight;
    }
    if (touchLocation.y > 768)
    {
        validLocation.y = 768;
    }
    if (touchLocation.x < 0)
    {
        validLocation.x = 0;
    }
    if (touchLocation.x > 1024)
    {
        validLocation.x = 1024;
    }
    
    return validLocation;
}

-(void)makeTouchesValidForRoundObjects
{
    CGPoint cSpaceStart = [self convertToCreationSpace:touchStartLocation];
    CGPoint cSpaceMoved = [self convertToCreationSpace:touchMovedLocation];
    CGFloat startToGroundDist = ccpDistance(cSpaceStart, ccp(cSpaceStart.x, GroundHeight));
    CGFloat touchDistance = ccpDistance(cSpaceMoved, cSpaceStart);
    
    if (startToGroundDist < MIN_WHEEL_LENGTH)
    {
        CGPoint adjustedCenter = ccp(cSpaceStart.x, GroundHeight+MIN_WHEEL_LENGTH);
        touchStartLocation = [self convertToActionSpace:adjustedCenter];
        //Readjust these based on new start position
        cSpaceStart = [self convertToCreationSpace:touchStartLocation];
        startToGroundDist = ccpDistance(cSpaceStart, ccp(cSpaceStart.x, GroundHeight));
        touchDistance = ccpDistance(cSpaceMoved, cSpaceStart);
    }
    
    if (touchDistance > startToGroundDist && startToGroundDist < MAX_WHEEL_LENGTH)
    {
        CGFloat angle = [self pointPairToBearingDegrees:cSpaceStart secondPoint:cSpaceMoved]+90.0f;
        touchMovedLocation = ccp(cSpaceStart.x, GroundHeight);
        touchMovedLocation = ccpRotateByAngle(touchMovedLocation, cSpaceStart, CC_DEGREES_TO_RADIANS(angle));
        touchMovedLocation = [self convertToActionSpace:touchMovedLocation];
    }
    lastValidCircleTouchLocation = touchMovedLocation;
}

-(CGPoint)convertToCreationSpace:(CGPoint)location
{
    CGPoint createLoc = ccp(location.x+layerToFollow.position.x, location.y+layerToFollow.position.y);
    return createLoc;
}

-(CGPoint)convertToActionSpace:(CGPoint)location
{
    CGPoint createLoc = ccp(location.x-layerToFollow.position.x, location.y-layerToFollow.position.y);
    return createLoc;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (isDeleteAllMenuUp) {[self slideDeleteMenuOut]; return NO;}
    if (isMotorMenuUp) {[self slideMotorMenuOut]; return NO;}
    if (isBoosterMenuUp) {[self slideBoosterMenuOut]; return NO;}
    
    if (selectedTool == toolTypeEdit && moveEditTouch != nil)
    {
        if (!rotateEditTouch)
        {
            [self rotatePartStarted:touch];
            return cartCreationEnabled;
        }else
        {
            return NO;
        }
    }
    
    touchStartLocation = [self convertTouchToNodeSpace:touch];
    touchStartLocation = [self convertToActionSpace:touchStartLocation];
    touchMovedLocation = touchStartLocation;
    touchEndLocation = touchStartLocation;
    lastValidCircleTouchLocation = touchStartLocation;
    lastValidTouchLocation = touchStartLocation;
    
    if ([self shouldAllowCartCreation] && [self touchIsValidForCreation:[self convertToCreationSpace:touchStartLocation]])
    {
        if ([self selectedToolIsLimited] && [self hasReachedMaxParts])
        {
            return NO;
        }

        switch (selectedTool)
        {
            case toolTypeNone:
                break;
            case toolTypeBar:
                [self createBarStarted];
                break;
            case toolTypeShock:
                [self createShockStarted:shockImageSet start:touchStartLocation];
                break;
            case toolTypeWheel:
                [self createWheelStarted];
                break;
            case toolTypeBooster:
            case toolTypeBooster50:
                [self createBoosterStarted];
                break;
            case toolTypeMotor:
            case toolTypeMotor50:
                [self createMotorStarted];
                break;
            case toolTypeDelete:
                [self deletePartStarted];
                break;
            case toolTypeEdit:
            {
                if (!moveEditTouch)
                {
                    [self editPartStarted:touch];
                }
            }
                break;
            default:
                break;
        }
    }
    
    if (selectedTool != toolTypeEdit && cartCreationEnabled)
    {
        creationTouch = touch;
    }
    
    return cartCreationEnabled;
}

-(BOOL)selectedToolIsLimited
{
    return selectedTool == toolTypeBooster
    || selectedTool == toolTypeBar
    || selectedTool == toolTypeMotor
    || selectedTool == toolTypeWheel
    || selectedTool == toolTypeMotor50
    || selectedTool == toolTypeBooster50;
}

-(BOOL)hasReachedMaxParts
{
    if ([cartCreationDelegate numberOfCartParts] >= MAX_CART_PARTS)
    {
        [ToolTipMenu displayWithMessage:@"You've reached the maximum number of parts.\n\nDelete a part to add more." plankCount:9];
        return YES;
    }
    return NO;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (touch == rotateEditTouch)
    {
        [self rotatePartMoved];
        return;
    }
    
    touchMovedLocation = [self convertTouchToNodeSpace:touch];
    touchMovedLocation = [self convertToActionSpace:touchMovedLocation];
    touchMovedLocation = [self makeTouchValidForCreation:[self convertToCreationSpace:touchMovedLocation]];
    touchMovedLocation = [self convertToActionSpace:touchMovedLocation];
    
    if (selectedTool == toolTypeEdit)
    {
        touchMovedLocation = [self makeEditTouchValid:touchMovedLocation];
        lastValidTouchLocation = touchMovedLocation;
    }
    
    if ([self shouldAllowCartCreation] && [self touchIsValidForCreation:[self convertToCreationSpace:touchStartLocation]])
    {
        switch (selectedTool)
        {
            case toolTypeNone:
                break;
            case toolTypeBar:
                [self createBarMoved];
                break;
            case toolTypeShock:
                [self createShockMoved:shockImageSet start:touchStartLocation end:touchMovedLocation];
                break;
            case toolTypeWheel:
                [self makeTouchesValidForRoundObjects];
                [self createWheelMoved];
                break;
            case toolTypeBooster:
            case toolTypeBooster50:
                [self createBoosterMoved];
                break;
            case toolTypeMotor:
            case toolTypeMotor50:
                [self makeTouchesValidForRoundObjects];
                [self createMotorMoved];
                break;
            case toolTypeDelete:
                [self deletePartMoved];
                break;
            case toolTypeEdit:
                {
                    if (touch == moveEditTouch)
                    {
                        [self editPartMoved];
                    }
                }
                break;
            default:
                break;
        }
    }else 
    {
        if (selectedTool == toolTypeDelete)
        {
            [self deletePartCanceled];
        }
    }
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event 
{
    if (touch == rotateEditTouch)
    {
        [self rotatePartEnded];
        return;
    }
    
    touchEndLocation = [self convertTouchToNodeSpace:touch];
    touchEndLocation = [self convertToActionSpace:touchEndLocation];
    touchEndLocation = [self makeTouchValidForCreation:[self convertToCreationSpace:touchEndLocation]];
    touchEndLocation = [self convertToActionSpace:touchEndLocation];
    
    if (selectedTool == toolTypeEdit)
    {
        touchEndLocation = lastValidTouchLocation;
    }
    
    if ([self shouldAllowCartCreation] && [self touchIsValidForCreation:[self convertToCreationSpace:touchStartLocation]])
    {
        switch (selectedTool)
        {
            case toolTypeNone:
                break;
            case toolTypeBar:
                [self createBarEnded];
                break;
            case toolTypeShock:
                [self createShockEndedStart:touchStartLocation end:touchEndLocation];
                break;
            case toolTypeWheel:
                touchEndLocation = lastValidCircleTouchLocation;
                [self createWheelEnded];
                break;
            case toolTypeBooster:
            case toolTypeBooster50:
                [self createBoosterEnded];
                break;
            case toolTypeMotor:
            case toolTypeMotor50:
                touchEndLocation = lastValidCircleTouchLocation;
                [self createMotorEnded];
                break;
            case toolTypeDelete:
                [self deletePartEnded];
                break;
            case toolTypeEdit:
            {
                if (touch == moveEditTouch)
                {
                    [self editPartEnded];
                }
            }
                break;
            default:
                break;
        }
    }

    if (touch == creationTouch)
    {
        creationTouch = nil;
    }
    [self removeAllTempImages];
}

-(void)selectToolType:(ToolType)type
{
    [self enableAllCreationMenuButtons];
    
    selectedTool = type;
    if (type != toolTypeBar)
        [barBtnSprite unselected];
    if (type != toolTypeWheel)
        [wheelBtnSprite unselected];
    if (type != toolTypeShock)
        [shockBtnSprite unselected];
    if (type != toolTypeBooster)
    {
        [boosterBtnSprite unselected];
        [self slideBoosterMenuOut];
    }
    if (type != toolTypeMotor)
    {
        [motorBtnSprite unselected];
        [self slideMotorMenuOut];
    }
    if (type != toolTypeDelete)
    {
        [deleteBtnSprite unselected];
        [self slideDeleteMenuOut];
    }
    if (type != toolTypeSave)
        [saveBtnSprite unselected];
    if (type != toolTypeShop)
        [shopBtnSprite unselected];
    if (type != toolTypeEdit)
    {
        [editBtnSprite unselected];
    }
}

-(void)DissableCartCreation
{
    cartCreationEnabled = NO;
}

-(void)createBarStarted
{
    [tempBar setPosition:ccp( touchStartLocation.x + [layerToFollow position].x, touchStartLocation.y + [layerToFollow position].y)];
    [tempBar setScaleX:MIN_BAR_LENGTH/tempBarOriginalLength];
    [self addChild:tempBar z:5];
}

-(void)createBarMoved
{
    float length = ccpDistance(touchStartLocation, touchMovedLocation);
    float rotation = -[self pointPairToBearingDegrees:touchStartLocation secondPoint:touchMovedLocation];
    CGPoint center = ccpMidpoint(touchStartLocation, touchMovedLocation);
    [tempBar setPosition:ccp(center.x+[layerToFollow position].x,center.y + [layerToFollow position].y)];
    [tempBar setScaleX:length/tempBarOriginalLength];
    [tempBar setRotation:rotation];
}

-(void)createBarEnded
{
    [tempBar setScaleX:1];
    if (MIN_BAR_LENGTH > ccpDistance(touchStartLocation, touchEndLocation))
        return;
    [cartCreationDelegate createBarWithStart:touchStartLocation andEnd:touchEndLocation];
}

-(void)editBarStarted
{
    float length = ccpDistance([editingPart start], [editingPart end]);
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    CGPoint center = ccpMidpoint([editingPart start], [editingPart end]);
    [tempBar setPosition:ccp(center.x+[layerToFollow position].x,center.y + [layerToFollow position].y)];
    [tempBar setScaleX:length/tempBarOriginalLength];
    [tempBar setRotation:rotation];
    [self addChild:tempBar z:5];
}

-(void)editBarMoved
{
    CGPoint center = ccpMidpoint([self offsetPoint:[editingPart start] forLoc:touchMovedLocation], [self offsetPoint:[editingPart end] forLoc:touchMovedLocation]);
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [tempBar setRotation:rotation];
    [tempBar setPosition:ccp(center.x+[layerToFollow position].x,center.y + [layerToFollow position].y)];
}

-(void)editBarEnd
{
    [tempBar setScaleX:1];
    [cartCreationDelegate createBarWithStart:[self offsetPoint:[editingPart start] forLoc:touchEndLocation] andEnd:[self offsetPoint:[editingPart end] forLoc:touchEndLocation]];
}

-(void)createWheelStarted
{
    [tempWheel setPosition:ccp(touchStartLocation.x + [layerToFollow position].x, touchStartLocation.y + [layerToFollow position].y)];
    [tempWheel setScale:(MIN_WHEEL_LENGTH*2)/tempWheelOriginalHeight];
    [self addChild:tempWheel z:5]; 
}

-(void)createWheelMoved
{
    float wheelDiameter = ccpDistance(touchStartLocation, touchMovedLocation)*2;
    if (wheelDiameter/2 > MAX_WHEEL_LENGTH)
        wheelDiameter = MAX_WHEEL_LENGTH*2;
    [tempWheel setScale:wheelDiameter/tempWheelOriginalHeight];
    
    float rotation = -[self pointPairToBearingDegrees:touchStartLocation secondPoint:touchMovedLocation];
    [tempWheel setRotation:rotation];
}

-(void)createWheelEnded
{
    [tempWheel setScale:1.0];
    if (MIN_WHEEL_LENGTH > ccpDistance(touchStartLocation, touchEndLocation))
        touchEndLocation = ccp(touchStartLocation.x+MIN_WHEEL_LENGTH, touchStartLocation.y);
    if (MAX_WHEEL_LENGTH < ccpDistance(touchStartLocation, touchEndLocation))
    {
        float rotation = [self pointPairToBearingDegrees:touchStartLocation secondPoint:touchEndLocation];
        touchEndLocation = ccp(touchStartLocation.x+MAX_WHEEL_LENGTH,touchStartLocation.y);
        touchEndLocation = ccpRotateByAngle(touchEndLocation, touchStartLocation, CC_DEGREES_TO_RADIANS(rotation));
    }
    [cartCreationDelegate createWheelWithStart:touchStartLocation andEnd:touchEndLocation];
}

-(void)editWheelStarted
{
    [tempWheel setPosition:ccp([editingPart start].x + [layerToFollow position].x, [editingPart start].y + [layerToFollow position].y)];
    float wheelDiameter = ccpDistance([editingPart start], [editingPart end])*2;
    if (wheelDiameter/2 > MAX_WHEEL_LENGTH)
        wheelDiameter = MAX_WHEEL_LENGTH*2;
    [tempWheel setScale:wheelDiameter/tempWheelOriginalHeight];
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [tempWheel setRotation:rotation];
    [self addChild:tempWheel z:5];
}

-(void)editWheelMoved
{
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [tempWheel setRotation:rotation];
    CGPoint center = [self offsetPoint:[editingPart start] forLoc:touchMovedLocation];
    [tempWheel setPosition:ccp(center.x + [layerToFollow position].x, center.y + [layerToFollow position].y)];
}

-(void)editWheelEnded
{
    [tempWheel setScale:1.0];
    [cartCreationDelegate createWheelWithStart:[self offsetPoint:[editingPart start] forLoc:touchEndLocation] andEnd:[self offsetPoint:[editingPart end] forLoc:touchEndLocation]];
}

-(void)createMotorStarted
{
    if (currentMotorType == toolTypeMotor)
    {
        currentMotor = tempMotor;
        currentMotorHub = tempMotorHub;
    }else if (currentMotorType == toolTypeMotor50)
    {
        currentMotor = tempMotor50;
        currentMotorHub = tempMotorHub50;
    }
    
    [currentMotor setPosition:ccp(touchStartLocation.x + [layerToFollow position].x, touchStartLocation.y + [layerToFollow position].y)];
    [currentMotor setScale:(MIN_WHEEL_LENGTH*2)/tempMotorOriginalHeight];
    [self addChild:currentMotor z:5];
}

-(void)createMotorMoved
{
    float motorDiameter = ccpDistance(touchStartLocation, touchMovedLocation)*2;
    if (motorDiameter/2 > MAX_WHEEL_LENGTH)
        motorDiameter = MAX_WHEEL_LENGTH*2;
    [currentMotor setScale:motorDiameter/tempMotorOriginalHeight];
    
    float rotation = -[self pointPairToBearingDegrees:touchStartLocation secondPoint:touchMovedLocation];
    [currentMotor setRotation:rotation];
    [currentMotorHub setRotation:-rotation];
}

-(void)createMotorEnded
{
    [currentMotor setScale:1.0];
    if (MIN_WHEEL_LENGTH > ccpDistance(touchStartLocation, touchEndLocation))
        touchEndLocation = ccp(touchStartLocation.x+MIN_WHEEL_LENGTH, touchStartLocation.y);
    if (MAX_WHEEL_LENGTH < ccpDistance(touchStartLocation, touchEndLocation))
    {
        float rotation = [self pointPairToBearingDegrees:touchStartLocation secondPoint:touchEndLocation];
        touchEndLocation = ccp(touchStartLocation.x+MAX_WHEEL_LENGTH,touchStartLocation.y);
        touchEndLocation = ccpRotateByAngle(touchEndLocation, touchStartLocation, CC_DEGREES_TO_RADIANS(rotation));
    }
    [cartCreationDelegate createMotorWithStart:touchStartLocation andEnd:touchEndLocation andType:[self gameObjectTypeFromTool:currentMotorType]];
}

-(void)editMotorStarted
{
    if ([editingPart gameObjectType] == kMotorPartType)
    {
        currentMotor = tempMotor;
        currentMotorHub = tempMotorHub;
    }else if ([editingPart gameObjectType] == kMotor50PartType)
    {
        currentMotor = tempMotor50;
        currentMotorHub = tempMotorHub50;
    }
    
    float motorDiameter = ccpDistance([editingPart start], [editingPart end])*2;
    if (motorDiameter/2 > MAX_WHEEL_LENGTH)
        motorDiameter = MAX_WHEEL_LENGTH*2;
    [currentMotor setScale:motorDiameter/tempMotorOriginalHeight];

    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [currentMotor setPosition:ccp([editingPart start].x + [layerToFollow position].x, [editingPart start].y + [layerToFollow position].y)];
    [currentMotor setRotation:rotation];
    [currentMotorHub setRotation:-rotation];
    [self addChild:currentMotor z:5];
}

-(void)editMotorMoved
{
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    CGPoint center = [self offsetPoint:[editingPart start] forLoc:touchMovedLocation];
    
    [currentMotor setRotation:rotation];
    [currentMotorHub setRotation:-rotation];
    [currentMotor setPosition:ccp(center.x + [layerToFollow position].x, center.y + [layerToFollow position].y)];
}

-(void)editMotorEnded
{
    [currentMotor setScale:1.0];
    [cartCreationDelegate createMotorWithStart:[self offsetPoint:[editingPart start] forLoc:touchEndLocation] andEnd:[self offsetPoint:[editingPart end] forLoc:touchEndLocation] andType:[editingPart gameObjectType]];
}

-(void)createShockStarted:(ShockImageSet*)imageSet start:(CGPoint)location
{
    [[imageSet tempShockBar] setScaleX:0];
    [[imageSet tempShockPiston] setScaleX:0];
    [[imageSet tempShockBar] setPosition:ccp(0, 0)];
    [[imageSet tempShockPiston] setPosition:ccp(0, 0)];
    [[imageSet tempShockBolt1] setPosition:ccp(-[[imageSet tempShockBolt1] boundingBox].size.width/2,0)];
    [[imageSet tempShockBolt2] setPosition:ccp([[imageSet tempShockBolt2] boundingBox].size.width/2,0)];
    [[imageSet tempShockPiston] setScaleX:0];
    [[imageSet tempShock] setPosition:ccp(location.x + [layerToFollow position].x, location.y + [layerToFollow position].y)];
    [self addChild:[imageSet tempShock] z:5];
}

-(void)createShockMoved:(ShockImageSet*)imageSet start:(CGPoint)start end:(CGPoint)end
{
    float length = ccpDistance(start, end);
    float barLength = length;
    if (barLength < 0){barLength = 0;}
    
    float rotation = -[self pointPairToBearingDegrees:start secondPoint:end];
    CGPoint center = ccpMidpoint(start, end);

    [[imageSet tempShockBar] setScaleX:barLength/[imageSet tempShockBarOriginalLength]];
    [[imageSet tempShockPiston] setScaleX:barLength/[imageSet tempShockBarOriginalLength]];
    [[imageSet tempShockBar] setPosition:ccp(0,0)];
    [[imageSet tempShockPiston] setPosition:ccp(0,0)];
    [[imageSet tempShockBolt1] setPosition:ccp(-length/2,0)];
    [[imageSet tempShockBolt2] setPosition:ccp(length/2,0)];
    [[imageSet tempShock] setRotation:rotation];
    [[imageSet tempShock] setPosition:ccp(center.x+[layerToFollow position].x,center.y + [layerToFollow position].y)];
}

-(void)createShockEndedStart:(CGPoint)start end:(CGPoint)end
{
    [cartCreationDelegate createShockWithStart:start andEnd:end];
}

-(void)editShockStarted
{
    float length = ccpDistance([editingPart start], [editingPart end]);
    float barLength = length;
    if (barLength < 0){barLength = 0;}
    
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    CGPoint center = ccpMidpoint([editingPart start], [editingPart end]);
    
    [[shockImageSet tempShockBar] setScaleX:barLength/[shockImageSet tempShockBarOriginalLength]];
    [[shockImageSet tempShockPiston] setScaleX:barLength/[shockImageSet tempShockBarOriginalLength]];
    [[shockImageSet tempShockBar] setPosition:ccp(0,0)];
    [[shockImageSet tempShockPiston] setPosition:ccp(0,0)];
    [[shockImageSet tempShockBolt1] setPosition:ccp(-length/2,0)];
    [[shockImageSet tempShockBolt2] setPosition:ccp(length/2,0)];
    [[shockImageSet tempShock] setRotation:rotation];
    [[shockImageSet tempShock] setPosition:ccp(center.x+[layerToFollow position].x,center.y + [layerToFollow position].y)];
    [self addChild:[shockImageSet tempShock] z:5];
}

-(void)editShockMoved
{
    CGPoint center = ccpMidpoint([self offsetPoint:[editingPart start] forLoc:touchMovedLocation], [self offsetPoint:[editingPart end] forLoc:touchMovedLocation]);
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [[shockImageSet tempShock] setRotation:rotation];
    [[shockImageSet tempShock] setPosition:ccp(center.x+[layerToFollow position].x,center.y + [layerToFollow position].y)];
}

-(void)editShockEnded
{
    [cartCreationDelegate createShockWithStart:[self offsetPoint:[editingPart start] forLoc:touchEndLocation] andEnd:[self offsetPoint:[editingPart end] forLoc:touchEndLocation]];
}

-(void)createBoosterStarted
{
    if (currentBoosterType == toolTypeBooster)
    {
        currentBooster = tempBooster;
    }else if (currentBoosterType == toolTypeBooster50)
    {
        currentBooster = tempBooster50;
    }

    [currentBooster setPosition:ccp(touchStartLocation.x + [layerToFollow position].x, touchStartLocation.y + [layerToFollow position].y)];
    [self addChild:currentBooster z:5];
}

-(void)createBoosterMoved
{
    float rotation = -[self pointPairToBearingDegrees:touchStartLocation secondPoint:touchMovedLocation];    
    [currentBooster setRotation:rotation];
}

-(void)createBoosterEnded
{
    [cartCreationDelegate createBoosterWithStart:touchStartLocation andEnd:touchEndLocation andType:[self gameObjectTypeFromTool:currentBoosterType]];
}

-(void)editBoosterStarted
{
    if ([editingPart gameObjectType] == kBoosterPartType)
    {
        currentBooster = tempBooster;
    }else if ([editingPart gameObjectType] == kBooster50PartType)
    {
        currentBooster = tempBooster50;
    }
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [currentBooster setRotation:rotation];
    [currentBooster setPosition:ccp([editingPart start].x + [layerToFollow position].x, [editingPart start].y + [layerToFollow position].y)];
    [self addChild:currentBooster z:5];
}

-(void)editBoosterMoved
{
    float rotation = -[self pointPairToBearingDegrees:[editingPart start] secondPoint:[editingPart end]];
    [currentBooster setRotation:rotation];
    [currentBooster setPosition:ccp([self offsetPoint:[editingPart start] forLoc:touchMovedLocation].x + [layerToFollow position].x, [self offsetPoint:[editingPart start] forLoc:touchMovedLocation].y + [layerToFollow position].y)];
}

-(void)editBoosterEnded
{
    [cartCreationDelegate createBoosterWithStart:[self offsetPoint:[editingPart start] forLoc:touchEndLocation] andEnd:[self offsetPoint:[editingPart end] forLoc:touchEndLocation] andType:[editingPart gameObjectType]];
}

-(BOOL)isEditTouchValid:(CGPoint)loc
{
    GameObjectType type = editingPart.gameObjectType;
    CGPoint creationStart = [self convertToCreationSpace:[self offsetPoint:[editingPart start] forLoc:loc]];
    CGPoint creationEnd = [self convertToCreationSpace:[self offsetPoint:[editingPart end] forLoc:loc]];
    
    if (![self touchIsValidForCreation:creationStart])
    {
        return NO;
    }
    if ((type == kBarPartType || type == kShockPartType) && ![self touchIsValidForCreation:creationEnd])
    {
        return NO;
    }
    if (type == kMotor50PartType || type == kMotorPartType || type == kWheelPartType)
    {
        CGFloat startToGroundDist = ccpDistance(creationStart, ccp(creationStart.x, GroundHeight));
        CGFloat touchDistance = ccpDistance(creationEnd, creationStart);
        if (touchDistance > startToGroundDist)
        {
            return NO;
        }
    }
    return YES;
}

-(CGPoint)makeEditTouchValid:(CGPoint)loc
{
    CGPoint outputLoc = loc;
    GameObjectType type = editingPart.gameObjectType;
    CGPoint creationStart = [self convertToCreationSpace:[self offsetPoint:[editingPart start] forLoc:loc]];
    CGPoint creationEnd = [self convertToCreationSpace:[self offsetPoint:[editingPart end] forLoc:loc]];

    if ((type == kBarPartType || type == kShockPartType))
    {
        if (![self touchIsValidForCreation:creationStart])
        {
            CGPoint newStart = [self makeTouchValidForCreation:creationStart];
            CGPoint diff = ccpSub(newStart, creationStart);
            outputLoc = ccpAdd(outputLoc, diff);
        }
        if (![self touchIsValidForCreation:creationEnd])
        {
            CGPoint newEnd = [self makeTouchValidForCreation:creationEnd];
            CGPoint diff = ccpSub(newEnd, creationEnd);
            outputLoc = ccpAdd(outputLoc, diff);
        }
    }
    if (type == kMotor50PartType || type == kMotorPartType || type == kWheelPartType)
    {
        CGPoint newStart = [self makeTouchValidForCreation:creationStart];
        CGPoint diff = ccpSub(newStart, creationStart);
        outputLoc = ccpAdd(outputLoc, diff);
        creationEnd = ccpAdd(creationEnd, diff);
        creationStart = newStart;
        
        CGFloat startToGroundDist = ccpDistance(creationStart, ccp(creationStart.x, GroundHeight));
        CGFloat touchDistance = ccpDistance(creationEnd, creationStart);
        
        if (touchDistance > startToGroundDist)
        {
            newStart = ccp(creationStart.x, GroundHeight+touchDistance);
            CGPoint diff = ccpSub(newStart, creationStart);
            outputLoc = ccpAdd(outputLoc, diff);
        }
    }
    
    if (type == kBoosterPartType || type == kBooster50PartType)
    {
        CGPoint newStart = [self makeTouchValidForCreation:creationStart];
        CGPoint diff = ccpSub(newStart, creationStart);
        outputLoc = ccpAdd(outputLoc, diff);
    }
    
    return outputLoc;
}

-(void)editPartStarted:(UITouch*)touch
{
    if (!editingShocks){ editingShocks = [[NSMutableArray alloc] init]; }
    if (!editingShockImages){ editingShockImages = [[NSMutableArray alloc] init]; }
    [editingShocks removeAllObjects];
    [editingShockImages removeAllObjects];
    [editingPart release];
    
    editingPart = [[cartCreationDelegate deletePartAtLocation:touchStartLocation outputShocks:editingShocks] retain];
    
    if (editingPart)
    {
        [[[CCDirector sharedDirector] view] setMultipleTouchEnabled:YES];
        [self dissableMenus];
        moveEditTouch = touch;
    }else
    {
        return;
    }
    
    switch ([editingPart gameObjectType])
    {
        case kMotorPartType:
        case kMotor50PartType:
            [self editMotorStarted];
            break;
        case kBoosterPartType:
        case kBooster50PartType:
            [self editBoosterStarted];
            break;
        case kWheelPartType:
            [self editWheelStarted];
            break;
        case kBarPartType:
            [self editBarStarted];
            break;
        case kShockPartType:
            [self editShockStarted];
            break;
        default:
            break;
    }
    
    for (CartPart *part in editingShocks)
    {
        ShockImageSet *imageSet = [[ShockImageSet alloc] init];
        [editingShockImages addObject:imageSet];
        [imageSet release];
        [self createShockStarted:imageSet start:[part start]];
        [self createShockMoved:imageSet start:[part start] end:[part end]];
    }
}

-(void)editPartMoved
{
    if (!editingPart)
    {
        return;
    }
    
    switch ([editingPart gameObjectType])
    {
        case kMotorPartType:
        case kMotor50PartType:
            [self editMotorMoved];
            break;
        case kBoosterPartType:
        case kBooster50PartType:
            [self editBoosterMoved];
            break;
        case kWheelPartType:
            [self editWheelMoved];
            break;
        case kBarPartType:
            [self editBarMoved];
            break;
        case kShockPartType:
            [self editShockMoved];
            break;
        default:
            break;
    }
    
    for (CartPart *part in editingShocks)
    {
        CGPoint newEnd = [self offsetPoint:[part end] forLoc:touchMovedLocation];
        [self createShockMoved:[editingShockImages objectAtIndex:[editingShocks indexOfObject:part]] start:[part start] end:newEnd];
    }
}

-(void)editPartEnded
{
    if (!editingPart)
    {
        return;
    }
    
    switch ([editingPart gameObjectType])
    {
        case kMotorPartType:
        case kMotor50PartType:
            [self editMotorEnded];
            break;
        case kBoosterPartType:
        case kBooster50PartType:
            [self editBoosterEnded];
            break;
        case kWheelPartType:
            [self editWheelEnded];
            break;
        case kBarPartType:
            [self editBarEnd];
            break;
        case kShockPartType:
            [self editShockEnded];
            break;
        default:
            break;
    }
    
    for (CartPart *part in editingShocks)
    {
        CGPoint newEnd = [self offsetPoint:[part end] forLoc:touchEndLocation];
        [self createShockEndedStart:[part start] end:newEnd];
    }
    
    [editingPart release];
    [editingShocks removeAllObjects];
    editingPart = nil;
    moveEditTouch = nil;
    rotateEditTouch = nil;
    [[[CCDirector sharedDirector] view] setMultipleTouchEnabled:NO];
    [self enableMenus];
}

-(void)rotatePartStarted:(UITouch*)touch
{
    if (!editingPart){return;}
    rotateEditTouch = touch;
    CGPoint startLocation = [self convertToCreationSpace:[self convertTouchToNodeSpace:moveEditTouch]];
    CGPoint endLocation = [self convertToCreationSpace:[self convertTouchToNodeSpace:rotateEditTouch]];
    rotateEditAngleStart = -[self pointPairToBearingDegrees:startLocation secondPoint:endLocation];
}

-(void)rotatePartMoved
{
    if (!editingPart){return;}
    CGPoint startLocation = [self convertToCreationSpace:[self convertTouchToNodeSpace:moveEditTouch]];
    CGPoint endLocation = [self convertToCreationSpace:[self convertTouchToNodeSpace:rotateEditTouch]];
    rotateEditAngleMove = -[self pointPairToBearingDegrees:startLocation secondPoint:endLocation];
    
    GameObjectType type = editingPart.gameObjectType;
    BOOL isValidRotation = NO;
    if (type == kBarPartType || type == kShockPartType)
    {
        isValidRotation = [self rotateEditPartAroundCenter];
    }else
    {
        isValidRotation = [self rotateEditPartAroundStart];
    }
    if (isValidRotation)
    {
        [self editPartMoved];
    }
}

-(void)rotatePartEnded
{
    if (!editingPart){return;}
    rotateEditTouch = nil;
}

-(BOOL)rotateEditPartAroundCenter
{
    float finalAngle = rotateEditAngleStart - rotateEditAngleMove;
    CGPoint center = ccpMidpoint([editingPart start], [editingPart end]);
    CGPoint start = [editingPart start];
    CGPoint end = [editingPart end];
    CGPoint newStart = ccpRotateByAngle(start, center, CC_DEGREES_TO_RADIANS(finalAngle)*3);
    CGPoint newEnd = ccpRotateByAngle(end, center, CC_DEGREES_TO_RADIANS(finalAngle)*3);
    
    [editingPart setStart:newStart];
    [editingPart setEnd:newEnd];
    
    if ([self isEditTouchValid: touchMovedLocation])
    {
        rotateEditAngleStart = rotateEditAngleMove;
        for (CartPart *part in editingShocks)
        {
            CGPoint sEnd = [part end];
            sEnd = ccpRotateByAngle(sEnd, center, CC_DEGREES_TO_RADIANS(finalAngle)*3);
            [part setEnd:sEnd];
        }
        return YES;
    }else
    {
        [editingPart setStart:start];
        [editingPart setEnd:end];
        return NO;
    }
}

-(BOOL)rotateEditPartAroundStart
{
    float finalAngle = rotateEditAngleStart - rotateEditAngleMove;
    CGPoint start = [editingPart start];
    CGPoint end = [editingPart end];
    CGPoint newEnd = ccpRotateByAngle(end, start, CC_DEGREES_TO_RADIANS(finalAngle)*3);
    [editingPart setEnd:newEnd];

    rotateEditAngleStart = rotateEditAngleMove;
    for (CartPart *part in editingShocks)
    {
        CGPoint sEnd = [part end];
        sEnd = ccpRotateByAngle(sEnd, start, CC_DEGREES_TO_RADIANS(finalAngle)*3);
        [part setEnd:sEnd];
    }
    return YES;
}

-(void)deletePartStarted
{
    [cartCreationDelegate deletePartStarted:touchStartLocation];
}

-(void)deletePartMoved
{
    [cartCreationDelegate deletePartMoved:touchMovedLocation];
}

-(void)deletePartEnded
{
    [cartCreationDelegate deletePartEnded];
}

-(void)deletePartCanceled
{
    [cartCreationDelegate deletePartCanceled];
}

-(void)saveCartSelected
{
    if (![cartCreationDelegate cartHasParts])
    {
        [ToolTipMenu displayWithMessage:@"Your cart must have parts!" plankCount:3];
        [saveMenu cancelSave];
        return;
    }
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:0];
    [tabMenu runAction:[[fade copy] autorelease]];
    [toolMenu runAction:[[fade copy] autorelease]];
    [saveMenu runAction:fade];
    [tabMenu setTouchEnabled:NO];
    [saveMenu setIsMenuEnabled:NO];
    [cartCreationDelegate saveCart];
  
}

-(void)saveCartComplete
{
    [tabMenu setTouchEnabled:YES];
    CCFadeTo *fadeBack = [CCFadeTo actionWithDuration:0.3 opacity:255];
    [tabMenu runAction:[[fadeBack copy] autorelease]];
    [toolMenu runAction:[[fadeBack copy] autorelease]];
    [saveMenu runAction:fadeBack];
}

-(void)dissableMenus
{
    [toolMenu setTouchEnabled:NO];
    [tabMenu setTouchEnabled:NO];
}

-(void)enableMenus
{
    [toolMenu setTouchEnabled:YES];
    [tabMenu setTouchEnabled:YES];
}

-(void)deleteItemSelected
{
    [self dissableMenus];
}

-(void)deleteItemComplete
{
    [self enableMenus];
}

-(void)calculateScore
{
    [timer pauseSchedulerAndActions];
    int timeScore = [timer getTimeScore];
    int totalPeons = [cartCreationDelegate getPeonCount];
    int shipPeons = [cartCreationDelegate getPodPeonCount];
    int percentageScore = ((float)shipPeons/(float)totalPeons)*timeScore;

    [levelScoreDisplay showScore:percentageScore peonCount:shipPeons totalPeons:totalPeons timerColor:[timer colorState] tmerState:[timer state] timeElapsed:[timer elapsedTime]];
    [timer resetTimer];
    [fuelGauge fadeOut];
    [tabMenu setOpacity:0];
    [tabMenu setTouchEnabled:NO];
    [timer resumeSchedulerAndActions];
}

-(double)pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    double bearingRadians = atan2(originPoint.y, originPoint.x); // get bearing in radians
    double bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
    bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return bearingDegrees;
}

-(GameObjectType)gameObjectTypeFromTool:(ToolType)tool
{
    switch (tool)
    {
        case toolTypeBooster:
            return kBoosterPartType;
            break;
        case toolTypeBooster50:
            return kBooster50PartType;
            break;
        case toolTypeMotor:
            return kMotorPartType;
            break;
        case toolTypeMotor50:
            return kMotor50PartType;
            break;
        default:
            return kObjectTypeNone;
            break;
    }
}

-(void)itemPurchased:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSString *pID= [userInfo objectForKey:@"ProductID"];
    if ([pID isEqualToString:PRODUCT_BOOST_50])
    {
        [self switchToBoosterType:toolTypeBooster50];
    }else if ([pID isEqualToString:PRODUCT_MOTOR_50])
    {
        [self switchToMotorType:toolTypeMotor50];
    }
}

-(CGPoint)offsetPoint:(CGPoint)point forLoc:(CGPoint)location
{
    CGPoint diff = ccp(location.x-touchStartLocation.x, location.y-touchStartLocation.y);
    CGPoint output = ccp(point.x+diff.x, point.y+diff.y);
    return output;
}

@end
