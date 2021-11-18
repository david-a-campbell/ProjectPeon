//
//  SaveMenu.m
//  rover
//
//  Created by David Campbell on 5/30/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "SaveMenu.h"
#import "Constants.h"
#import "SaveManager.h"

@implementation SaveMenu
@synthesize isMenuDisplaying, delegate;

-(id)init
{
    if ((self = [super init]))
    {
        [self setupMenuImages];
        isMenuDisplaying = NO;
        isSaving = NO;
        didScroll = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadScrollview) name:NOTIFICATION_SAVE_CART_COMPLETE object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self deallocScrollview];
    [super dealloc];
}

-(void)deallocScrollview
{
    [scrollview removeFromParentAndCleanup:YES];
    [scrollview release];
    scrollview = nil;
    [saveMenuItemList release];
    saveMenuItemList = nil;
    [[SaveManager sharedManager] releaseSavedData];
}

-(void)setupMenuImages
{
    blueprints_background = [CCMenuItemImage itemWithNormalImage:@"blueprints_background.png" selectedImage:nil];
    blueprints_left_1 = [CCSprite spriteWithSpriteFrameName:@"blueprints_left_1.png"];
    blueprints_left_2 = [CCSprite spriteWithSpriteFrameName:@"blueprints_left_2.png"];
    blueprints_right_1 = [CCSprite spriteWithSpriteFrameName:@"blueprints_right_1.png"];
    blueprints_right_2 = [CCSprite spriteWithSpriteFrameName:@"blueprints_right_2.png"];
    
    [blueprints_background setScale:2*(SCREEN_SCALE)];
    [blueprints_left_1 setScale:2*(SCREEN_SCALE)];
    [blueprints_left_2 setScale:2*(SCREEN_SCALE)];
    [blueprints_right_1 setScale:2*(SCREEN_SCALE)];
    [blueprints_right_2 setScale:2*(SCREEN_SCALE)];
    
    [blueprints_background setPosition:ccp(512.0f, 627.5f)];
    [blueprints_left_1 setPosition:ccp(-23.5f, 626.135f)];
    [blueprints_right_1 setPosition:ccp(1047.5f, 626.135f)];
    [blueprints_left_2 setPosition:ccp(-48.0f, 625.449f)];
    [blueprints_right_2 setPosition:ccp(1072.0f, 625.449f)];
    [blueprints_background setOpacity:0];
    
    [self addChild:blueprints_background z:-2];
    [self addChild:blueprints_left_2];
    [self addChild:blueprints_right_2];
    [self addChild:blueprints_left_1];
    [self addChild:blueprints_right_1];
}

-(void)getSavedCarts
{
    if (saveMenuItemList != nil)
    {
        [saveMenuItemList release];
        saveMenuItemList = nil;
    }
    [[SaveManager sharedManager] loadSavedData];
    saveMenuItemList = [[NSMutableArray alloc] init];
    for (int x = 0; x < [[SaveManager sharedManager] numberOfSavedCarts]; x++)
    {
        SaveMenuItem *savedCartItem = [[SaveMenuItem alloc] initWithImage:[[SaveManager sharedManager] imageForIndex:x] andIndex:x];
        [savedCartItem setSaveDelegate:self];
        [saveMenuItemList addObject:savedCartItem];
        [savedCartItem release];
    }
    SaveMenuItem *saveBtn = [[SaveMenuItem alloc] initAsSaveItem];
    [saveBtn setSaveDelegate:self];
    [saveMenuItemList addObject:saveBtn];
    [saveBtn release];
}

-(void)setupScrollview
{
    float xSpacing = 85;
    if (scrollview == nil) {
        scrollview = [[SWScrollView alloc] initWithViewSize:CGSizeMake(935, 146)];
    }else {
        return;
    }
    [scrollview setDirection: SWScrollViewDirectionHorizontal];
    [scrollview setPosition:ccp(44.5, 554.835)];
    [scrollview setContentOffset:ccp(0,0)];
    for (SaveMenuItem *item in [saveMenuItemList reverseObjectEnumerator])
    {
        [item setPosition:ccp(xSpacing, 73)];
        [scrollview addChild:item z:-1];
        xSpacing = xSpacing + 175;
    }
    [self addChild:scrollview z:-1];
    float contentWidth = 935;
    if (xSpacing > contentWidth)
    {
        contentWidth = xSpacing;
    }
    [scrollview setContentSize:CGSizeMake(contentWidth, 146)];
    [scrollview setDelegate:self];
    [self fadeInMenuItems];
}

-(void)reloadScrollview
{
    [self deallocScrollview];
    [self getSavedCarts];
    [self setupScrollview];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FADE_SAVE_BACKING object:nil];
    [delegate saveCartComplete];
    id sequence = [CCSequence actions:[CCDelayTime actionWithDuration:0.4], [CCCallFunc actionWithTarget:self selector:@selector(saveCartComplete)],nil];
    [blueprints_background runAction:sequence];
}

-(void)saveCartComplete
{
    SaveMenuItem *btn = [saveMenuItemList lastObject];
    [btn enable];
    isSaving = NO;
    [self setIsMenuEnabled:YES];   
}

-(void)showMenu
{    
    [self slideOuterMenuIn];
}

-(void)dissmissMenu
{
    if (expandedItem != nil)
    {
        [expandedItem collapseView];
    }
    expandedItem = nil;
    [self fadeMiddleOut];
}

-(void)slideOuterMenuIn
{
    id moveActionLeft = [CCMoveTo actionWithDuration:0.1f position:ccp(22.5f , 626.135f)];
    id moveActionRight = [CCMoveTo actionWithDuration:0.1f position:ccp(1001.5f , 626.135f)];
    id moveEffectLeft = [CCEaseIn actionWithAction:moveActionLeft rate:0.2f];
    id moveEffectRight = [CCEaseIn actionWithAction:moveActionRight rate:0.2f];
    id sequence = [CCSequence actions:moveEffectLeft, [CCCallFunc actionWithTarget:self selector:@selector(slideInnerMenuIn)], nil];
    [blueprints_left_1 runAction:sequence];
    [blueprints_right_1 runAction:moveEffectRight];
}

-(void)slideInnerMenuIn
{
    id moveActionLeft = [CCMoveTo actionWithDuration:0.1f position:ccp(47.0f , 625.449f)];
    id moveActionRight = [CCMoveTo actionWithDuration:0.1f position:ccp(977.0f , 625.449f)];
    id moveEffectLeft = [CCEaseOut actionWithAction:moveActionLeft rate:0.2f];
    id moveEffectRight = [CCEaseOut actionWithAction:moveActionRight rate:0.2f];
    id sequence = [CCSequence actions:moveEffectLeft, [CCCallFunc actionWithTarget:self selector:@selector(fadeMiddleIn)], nil];
    [blueprints_left_2 runAction:sequence];
    [blueprints_right_2 runAction:moveEffectRight];
}

-(void)fadeMiddleIn
{
    id fadeAction = [CCFadeTo actionWithDuration:0.1f opacity:255];
    id sequence = [CCSequence actions:fadeAction, [CCCallFunc actionWithTarget:self selector:@selector(fadeMiddleInComplete)], nil];
    [blueprints_background runAction:sequence];
}

-(void)fadeMiddleInComplete
{
    [self getSavedCarts];
    [self setupScrollview];
    [NSThread detachNewThreadSelector:@selector(setupScrollview) toTarget:self withObject:nil];
    isMenuDisplaying = YES;
    [self setIsMenuEnabled:YES];
}

-(void)slideInnerMenuOut
{
    id moveActionLeft = [CCMoveTo actionWithDuration:0.1f position:ccp(-48.0f , 625.449f)];
    id moveActionRight = [CCMoveTo actionWithDuration:0.1f position:ccp(1072.0f , 625.449f)];
    id moveEffectLeft = [CCEaseOut actionWithAction:moveActionLeft rate:0.2f];
    id moveEffectRight = [CCEaseOut actionWithAction:moveActionRight rate:0.2f];
    id sequence = [CCSequence actions:moveEffectLeft, [CCCallFunc actionWithTarget:self selector:@selector(slideOuterMenuOut)], nil];
    [blueprints_right_2 runAction:moveEffectRight];    
    [blueprints_left_2 runAction:sequence];
}

-(void)slideOuterMenuOut
{
    id moveActionLeft = [CCMoveTo actionWithDuration:0.1f position:ccp(-23.5f , 626.135f)];
    id moveActionRight = [CCMoveTo actionWithDuration:0.1f position:ccp(1047.5f , 626.135f)];
    id moveEffectLeft = [CCEaseOut actionWithAction:moveActionLeft rate:0.2f];
    id moveEffectRight = [CCEaseOut actionWithAction:moveActionRight rate:0.2f];
    [blueprints_left_1 runAction:moveEffectLeft];
    [blueprints_right_1 runAction:moveEffectRight];
    [delegate saveMenuDidDismiss];
}

-(void)fadeMiddleOut
{
    id fadeAction = [CCFadeTo actionWithDuration:0.1f opacity:0];
    id sequence = [CCSequence actions:fadeAction, [CCCallFunc actionWithTarget:self selector:@selector(slideInnerMenuOut)], nil];
    [blueprints_background runAction:sequence];
    [self fadeOutMenuItems];
    isMenuDisplaying = NO;
    [self setIsMenuEnabled:NO];
}

//Delegate Methods
-(void)cartSaveSelected
{
    isSaving = YES;
    expandedItem = nil;
    [delegate saveCartSelected];
}

-(void)cancelSave
{
    isSaving = NO;
    [self enableAllMenuItems];
}

-(void)loadCartSelected
{
    expandedItem = nil;
    [scrollview setTouchEnabled:YES];
}

-(void)deleteCartSelected:(int)index
{
    expandedItem = nil;
    CCMoveBy *move = [CCMoveBy actionWithDuration:0.2f position:ccp(-175,0)];
    for (int x = 0; x < index; x++) 
    {
        SaveMenuItem *item = [saveMenuItemList objectAtIndex:x];
        [item runAction:[[move copy] autorelease]];
    }

    SaveMenuItem *item = [saveMenuItemList objectAtIndex:index];
    [item removeFromParentAndCleanup:YES];
    [saveMenuItemList removeObject:item];
    for (SaveMenuItem *item in saveMenuItemList)
    {
        [item setIndex:[saveMenuItemList indexOfObject:item]];
    }
    float xSpacing = [scrollview contentSize].width - 175;
    float contentWidth = 935;
    if (xSpacing > contentWidth)
    {
        contentWidth = xSpacing;
    }
    [scrollview setContentSize:CGSizeMake(contentWidth, 146)];
    [scrollview setTouchEnabled:YES];
    [self enableAllMenuItems];
}

-(void)expandViewSelected:(id)item
{
    [self setIsMenuEnabled:NO];
    if (expandedItem != nil) 
    {
        [expandedItem collapseView];
    }
    expandedItem = (SaveMenuItem*)item;
    CGPoint offset = ccp(-expandedItem.position.x+512-44.5, 0);
    [scrollview setContentOffset:offset animatedInDuration:0.3];
}

-(void)expandViewComplete
{
    [self enableAllMenuItems];
    [self setTouchEnabled:YES];
    [expandedItem dissable];
}

-(void)minimizeSelected
{
    expandedItem = nil;
    [scrollview setTouchEnabled:YES];
}

-(void)dissableAllMenuItems
{
    for (SaveMenuItem *item in saveMenuItemList)
    {
        [item dissable];
    }
    menuItemsEnabled = NO;
}

-(void)enableAllMenuItems
{
    for (SaveMenuItem *item in saveMenuItemList)
    {
        [item enable];
    }
    menuItemsEnabled = YES;
}

-(void)fadeOutMenuItems
{
    for (SaveMenuItem *item in saveMenuItemList)
    {
        id fadeAction = [CCFadeTo actionWithDuration:0.2f opacity:0];
        [item runAction:fadeAction];
    }
}

-(void)fadeInMenuItems
{
    CCFadeTo *fadeAction = [CCFadeTo actionWithDuration:0.2f opacity:255];
    for (SaveMenuItem *item in saveMenuItemList)
    {
        [item runAction:[[fadeAction copy] autorelease]];
    }
    [self setHandlerPrioWithDelay:0.1];
}

-(void)setOpacity:(GLubyte)opacity
{
    [blueprints_background setOpacity:opacity];
    [blueprints_left_1 setOpacity:opacity];
    [blueprints_left_2 setOpacity:opacity];
    [blueprints_right_1 setOpacity:opacity];
    [blueprints_right_2 setOpacity:opacity];
    for (SaveMenuItem *item in saveMenuItemList)
    {
        [item setOpacity:opacity];
    }
}

-(void)runAction:(CCAction *)action
{
    [blueprints_background runAction:[[action copy]autorelease]];
    [blueprints_left_1 runAction:[[action copy]autorelease]];
    [blueprints_left_2 runAction:[[action copy]autorelease]];
    [blueprints_right_1 runAction:[[action copy]autorelease]];
    [blueprints_right_2 runAction:[[action copy]autorelease]];
    for (SaveMenuItem *item in saveMenuItemList)
    {
        [item runAction:[[action copy]autorelease]];
    }
}

-(void)setIsMenuEnabled:(BOOL)isTouchEnabled
{
    if (isTouchEnabled)
    {
        [self enableAllMenuItems];
    }else {
        [self dissableAllMenuItems];
    }
    [scrollview setTouchEnabled:isTouchEnabled];
    [self setTouchEnabled:isTouchEnabled];
}

-(void)scrollViewDidScroll:(SWScrollView *)view withTouch:(BOOL)isTouching
{
    if (menuItemsEnabled && isTouching)
    {
        didScroll = YES;
        [self dissableAllMenuItems];
    }
}

-(void)scrollViewDidEndTouch
{
    if (!menuItemsEnabled && !isSaving && didScroll) {
        didScroll = NO;
        [self enableAllMenuItems];
    }
}

-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-500 swallowsTouches:YES];
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (expandedItem != nil)
    {
        //Center of box is at (512, 327.83)
        CGRect boundingBox = CGRectMake(296.96, 166.55, 430.08, 322.56);
        CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
        touchLocation = ccp(touchLocation.x, touchLocation.y);
        if (!CGRectContainsPoint(boundingBox, touchLocation)) {
                [expandedItem minimize];
        }
    }else {
        [self dissmissMenu];
    }

    return YES;
}

-(void)setHandlerPrioWithDelay:(float)delay
{
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:delay], [CCCallFunc actionWithTarget:self  selector:@selector(setHandlerPriorities)], nil]];
}

-(void)setHandlerPriorities
{
    if ([scrollview isTouchEnabled])
    {
        [scrollview setHandlerPriority:-501];
    }
    for (SaveMenuItem *item in saveMenuItemList)
    {
        if ([item isTouchEnabled])
        {
            [item setHandlerPriority:-502];
        }
    }
}

@end
