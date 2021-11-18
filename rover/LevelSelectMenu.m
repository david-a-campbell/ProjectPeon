//
//  LevelSelectMenu.m
//  rover
//
//  Created by David Campbell on 6/17/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "LevelSelectMenu.h"
#import "Constants.h"
#import "LevelSelectMenuItem.h"
#import "SaveManager.h"
#import "GameManager.h"

@implementation LevelSelectMenu
@synthesize delegate;
-(id)initWithPlanetNum:(int)planetToLoad
{
    if ((self = [super init]))
    {
        menuItemList = [[NSMutableArray alloc] init];
        [self setupScrollview];
        [scrollview setDelegate:self];
        currentPlanet = planetToLoad;

        [self configureForPlanetNumber:currentPlanet];
        [self setupPlanetSelectButtons];
        [self setupPopupMenu];
        didScroll = NO;
        menuItemsEnabled = YES;
    }
    return self;
}

-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:3 swallowsTouches:YES];
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}

-(void)setupScrollview
{
    scrollview = [[SWScrollView alloc] initWithViewSize:CGSizeMake(1582.25, 558.5)];
    [scrollview setAnchorPoint:ccp(0, 0)];
    [scrollview setDirection: SWScrollViewDirectionHorizontal];
    [scrollview setContentOffset:ccp(0,0)];

    float x = 0;
    float shift = 548;
    for (int i = 0; i<4; i++)
    {
        CCSprite *hex = [CCSprite spriteWithSpriteFrameName:@"levelSelect_menuHex.png"];
        [[hex texture] setAliasTexParameters];
        [hex setScale:2.0*(SCREEN_SCALE)];
        [hex setPosition:ccp(x, AdOffset)];
        x+=shift;
        [scrollview addChild:hex];
    }
    [scrollview setContentSize:CGSizeMake(1644, 558.5)];
    [scrollview setPosition:ccp(-618, 138.75)];
    //Set to no for this release scince there are only 10 levels per planet
    [scrollview setTouchEnabled:NO];
    [self addChild:scrollview];
    [scrollview release];
}

-(void)configureForPlanetNumber:(int)planetNum
{
    int highestUnlockedLevel = [[SaveManager sharedManager] getHighestLevelUnlockedForPlanet:planetNum];
    BOOL state = YES;
    float x = 1224.005;
    float y = 309.25+AdOffset;
    float downDistance = 94.5+9;
    float distanceAccross = 91.0;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setRoundingMode:NSNumberFormatterRoundCeiling];
    NSNumber *numberOfLevels = [NSNumber numberWithInt:[[SaveManager sharedManager] numberOfLevelsForPlanetNumber:planetNum]];
    NSNumber *columns = [NSNumber numberWithFloat:([numberOfLevels floatValue]/3.0)];
    columns = [formatter numberFromString:[formatter stringFromNumber:columns]];
    
    for (int i = 0; i < [columns intValue]; i++)
    {
        for (int k = 1; k < 4; k++) 
        {
            int levelNum = (i*3+k);
            if (levelNum > highestUnlockedLevel) {
                //TODO_DAVID uncomment out this line to lock all levels
                state = NO;
            }
            if (levelNum>[numberOfLevels intValue]) {break;}
            LevelSelectMenuItem *item = [[LevelSelectMenuItem alloc] initWithState:state andLevelNum:levelNum planetNum:planetNum];
            [item setDelegate:self];
            [item setPosition:ccp(x, y)];
            [scrollview addChild:item];
            [menuItemList addObject:item];
            [item release];
            y -= downDistance;
        }
        x += distanceAccross;
        if ((i%2)==0)
        {
            y = 361.5+AdOffset;
        }else {
            y = 309.25+AdOffset;
        }
    }
    [formatter release];
}

-(void)clearScrollViewAndItemList
{
    for (LevelSelectMenuItem *item in menuItemList) {
        [item removeFromParentAndCleanup:YES];
    }
    [menuItemList removeAllObjects];
}

-(void)setupPlanetSelectButtons
{
    CCSprite *right = [CCSprite spriteWithSpriteFrameName:@"levelSelect_planetNext_1.png"];
    CCSprite *rightSel = [CCSprite spriteWithSpriteFrameName:@"levelSelect_planetNext_sel_1.png"];
    CCSprite *left = [CCSprite spriteWithSpriteFrameName:@"levelSelect_planetPrevious_1.png"];
    CCSprite *leftSel = [CCSprite spriteWithSpriteFrameName:@"levelSelect_planetPrevious_sel_1.png"];
    
    [[right texture] setAliasTexParameters];
    [[rightSel texture] setAliasTexParameters];
    [[left texture] setAliasTexParameters];
    [[leftSel texture] setAliasTexParameters];
    
    nextPlanet = [CCMenuItemSprite itemWithNormalSprite:right selectedSprite:rightSel disabledSprite:nil target:self selector:@selector(nextPlanetSelected)];
    prevPlanet = [CCMenuItemSprite itemWithNormalSprite:left selectedSprite:leftSel disabledSprite:nil target:self selector:@selector(prevPlanetSelected)];
    [nextPlanet setScale:2.0*(SCREEN_SCALE)];
    [prevPlanet setScale:2.0*(SCREEN_SCALE)];
    CCSprite *rightBackground = [CCSprite spriteWithSpriteFrameName:@"levelSelect_infoPanelLeft.png"];
    CCSprite *leftBackground = [CCSprite spriteWithSpriteFrameName:@"levelSelect_infoPanelRight.png"];
    [[rightBackground texture] setAliasTexParameters];
    [[leftBackground texture] setAliasTexParameters];
    [rightBackground setScale:2.0*(SCREEN_SCALE)];
    [leftBackground setScale:2.0*(SCREEN_SCALE)];
    [rightBackground setPosition:ccp(949, 39)];
    [leftBackground setPosition:ccp(75, 39)];
    [nextPlanet setPosition:ccp(949+35, 39)];
    [prevPlanet setPosition:ccp(75-35, 39)];
    
    planetSelectMenu = [CCMenu menuWithItems: nextPlanet, prevPlanet, nil];
    [planetSelectMenu setPosition:ccp(0, 0)];
    
    [self addChild:leftBackground z:-10];
    [self addChild:rightBackground z:-10];
    [self addChild:planetSelectMenu];
}

-(void)nextPlanetSelected
{
    [self clearScrollViewAndItemList];
    
    int numOfPlanets = [[SaveManager sharedManager] numberOfPlanets];
    int modValue = (currentPlanet+1)%numOfPlanets;
    currentPlanet = modValue ==0? numOfPlanets:modValue;

    [delegate planetSelected:currentPlanet];
    [self configureForPlanetNumber:(currentPlanet)];
}

-(void)prevPlanetSelected
{
    [self clearScrollViewAndItemList];
    
    int numOfPlanets = [[SaveManager sharedManager] numberOfPlanets];
    int modValue = abs((currentPlanet-1)%numOfPlanets);
    currentPlanet = modValue==0? numOfPlanets:modValue;
    
    [delegate planetSelected:currentPlanet];
    [self configureForPlanetNumber:(currentPlanet)];
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
    if (!menuItemsEnabled && didScroll) {
        didScroll = NO;
        [self enableAllMenuItems];
    }
}

-(void)dissableAllMenuItems
{
    for (LevelSelectMenuItem *item in menuItemList)
    {
        [item dissable];
    }
    menuItemsEnabled = NO;
}

-(void)enableAllMenuItems
{
    for (LevelSelectMenuItem *item in menuItemList)
    {
        [item enable];
    }
    menuItemsEnabled = YES;
}

-(void)loadLevelSelected:(int)levelNum
{
    [[GameManager sharedGameManager] playSoundEffect:@"levelSelect.mp3"];
    [self dissableAllMenuItems];
    [[GameManager sharedGameManager] runPlanet:currentPlanet level:levelNum];
    [[GameManager sharedGameManager] setCurrentPlanetNum:currentPlanet];
    [[GameManager sharedGameManager] setCurrentLevelNum:levelNum];
}

//PopupMenuStuff

-(void)setupPopupMenu
{
    tabMenuSprite = [CCMenuItemSprite   itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"menu_callTab_1.png"]
                                              selectedSprite:  [CCSprite spriteWithSpriteFrameName:@"menu_callTab_sel_1.png"] 
                                                       block:^(id sender) 
                     {
                         [PopupMenu showPopupMenuType:kPopupTypeLevelSelect withDelegate:self];
                     }];
    [tabMenuSprite setScale:2.0*(SCREEN_SCALE)];
    
    tabMenu = [CCMenu menuWithItems:tabMenuSprite, nil];
    [tabMenu setPosition:ccp(966.5, 735.5)];
    [self addChild:tabMenu];
}

-(void)popupDidDismiss:(PopupType)type
{
    [tabMenu setTouchEnabled:YES];
    [planetSelectMenu setTouchEnabled:YES];
    [self enableAllMenuItems];
}

-(void)dealloc
{
    [menuItemList release];
    menuItemList = nil;
    [super dealloc];
}
@end
