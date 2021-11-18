//
//  popupMenu.m
//  rover
//
//  Created by David Campbell on 5/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "PopupMenu.h"
#import "cocos2d.h"
#import "Constants.h"
#import "GameManager.h"
#import "SaveManager.h"
#import "PopupLevelSelect.h"
#import "PopupCartCreation.h"
#import "PopupGamePlay.h"
#import "PlankObject.h"
#import "PopupSettings.h"
#import "PopupStore.h"
#import "PopupTitleSettings.h"
#import "PopupGameInfo.h"
#import "InstructionLayer.h"

static PopupMenu *_currentDisplay;

@implementation PopupMenu

+(void)showPopupMenuType:(PopupType)type withDelegate:(id<popupMenuDelegate>)popupDelegate
{
    [PopupMenu dismissPopup];
    _currentDisplay = [[PopupMenu alloc] initForType:type andDelegate:popupDelegate];
    CCScene *runningScene = [[CCDirector sharedDirector] runningScene];
    [runningScene addChild:_currentDisplay z:1000000];
    [_currentDisplay release];
}

+(void)dismissPopup
{
    if (_currentDisplay)
    {
        [_currentDisplay removeFromParentAndCleanup:YES];
        _currentDisplay = nil;
    }
}

+(void)setCurrentDisplay:(PopupMenu*)currentDisplay
{
    _currentDisplay = currentDisplay;
}

-(id)initForType:(PopupType)t andDelegate:(id<popupMenuDelegate>)popupDelegate
{
    if ((self = [super init]))
    {
        type = t;
        _popupDelegate = popupDelegate;
        isClosing = NO;
        volumeChanged = NO;
        [self createMenu];
        [self setupEmitter];
        [self setTouchEnabled:YES];
        [self setupMenuType];
        [self showPopup];
    }
    return self;
}

-(BOOL)isWide
{
    return type == kPopupStore;
}

-(void)createMenu
{    
    [self setAnchorPoint:ccp(0.5, 0.5)];
    [self setPosition:ccp(512, 384)];
    
    if ([self isWide])
    {
        top = [CCSprite spriteWithFile:@"shopFrame_1.png"];
        bottom = [CCSprite spriteWithFile:@"shopFrame_3.png"];
    }else
    {
        top = [CCSprite spriteWithFile:@"toolTip_1.png"];
        bottom = [CCSprite spriteWithFile:@"toolTip_3.png"];
    }
    overlay = [CCSprite spriteWithFile:@"darkOverlayOpaque.png"];
    backOverlay = [CCSprite spriteWithFile:@"darkOverlay93.png"];
    
    [top setScale:2*SCREEN_SCALE];
    [bottom setScale:2*SCREEN_SCALE];
    [overlay setScale:2*(SCREEN_SCALE)];
    [backOverlay setScale:2*(SCREEN_SCALE)];
    topOriginalPos = ccp(0, 24-15);
    bottomOriginalPos = ccp(0, -23.5+7);
    [top setPosition:topOriginalPos];
    [bottom setPosition:bottomOriginalPos];
    [overlay setPosition:ccp(0,0)];
    [backOverlay setPosition:ccp(0,0)];
    [top setOpacity:0];
    [bottom setOpacity:0];
    [overlay setOpacity:0];
    [backOverlay setOpacity:0];
    [self addChild:top z:1];
    [self addChild:bottom z:0];
    [self addChild:overlay z:-10];
    [self addChild:backOverlay z:-12];
}

-(BasePopupMenu*)menuForCurrentType
{
    switch (type)
    {
        case kPopupTypeLevelSelect:
            return [[[PopupLevelSelect alloc] initWithDelegate:self] autorelease];
            break;
        case kPopupTypeCartCreation:
            return [[[PopupCartCreation alloc] initWithDelegate:self] autorelease];
            break;
        case kPopupTypeGamePlay:
            return [[[PopupGamePlay alloc] initWithDelegate:self] autorelease];
            break;
        case kPopupSettings:
            return [[[PopupSettings alloc] initWithDelegate:self forGameplay:[self isGameplayMenu]] autorelease];
            break;
        case kPopupTitleSettings:
            return [[[PopupTitleSettings alloc] initWithDelegate:self forGameplay:[self isGameplayMenu]] autorelease];
            break;
        case kPopupStore:
            return [[[PopupStore alloc] initWithDelegate:self] autorelease];
            break;
        case kPopupGameInfo:
            return [[[PopupGameInfo alloc] initWithDelegate:self] autorelease];
            break;
        default:
            return nil;
            break;
    }
}

-(BOOL)isGameplayMenu
{
    return ([[menuStack objectAtIndex:0] intValue] == kPopupTypeCartCreation || [[menuStack objectAtIndex:0] intValue] == kPopupTypeGamePlay);
}

-(void)setupMenuType
{
    if (!menuStack)
    {
        menuStack = [[NSMutableArray alloc] init];
    }
    [menuStack addObject:[NSNumber numberWithInt:type]];
    
    if (currentOptions)
    {
        [currentOptions removeFromParent];
        [currentOptions release];
    }
    currentOptions = [[self menuForCurrentType] retain];
    if (plankArray)
    {
        [plankArray makeObjectsPerformSelector:@selector(removeFromParent)];
        [plankArray release];
    }
    plankArray = [[NSMutableArray alloc] init];
    
    for (int count = 0; count < [currentOptions numberOfPlanks]; count++)
    {
        CCSprite *plank;
        if ([self isWide])
        {
            plank = [CCSprite spriteWithFile:@"shopFrame_2.png"];
        }else
        {
            plank = [CCSprite spriteWithFile:@"toolTip_2.png"];
        }
        
        [plank setScale:2*SCREEN_SCALE];
        [plank setPosition:ccp(0, 0)];
        [plank setOpacity:0];
        [self addChild:plank z:-1];
        
        PlankObject *plankObject = [[PlankObject alloc] init];
        [plankObject setPlank:plank];
        [plankObject setFinalPosition:ccp(0, [self plankHeightForPosition:count])];
        [plankArray addObject:plankObject];
        [plankObject release];
    }
    
    [currentOptions setOpacity:0];
    [currentOptions setOpacity:0];
    [currentOptions addToNode:self];
}

-(float)plankHeightForPosition:(int)position
{
    float height = -1 * (position*18 + 9);
    height = height+(18*[currentOptions numberOfPlanks])/2.0f;
    return height;
}

-(float)getMenuHeight
{
    return ccpDistance([top position], [bottom position]) + 48;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    float menuWidth = [top boundingBox].size.width;
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CGRect boundingBox = CGRectMake(0, 0, menuWidth, [self getMenuHeight]);
    touchLocation = ccp(touchLocation.x + menuWidth/2.0f, touchLocation.y + [self getMenuHeight]/2.0f);
    
    if (!isClosing)
    {
        if(!CGRectContainsPoint(boundingBox, touchLocation))
        {
            [self hide];
        }
    }
    //Must return yes to swallow touches
    return YES;
}

-(void)fadeInEnd
{
    CCFadeTo *listFade = [CCFadeTo actionWithDuration:0.5 opacity:255];
    [currentOptions runAction:listFade];
    [currentOptions setHandlerPriority:-1001];
    
    [menuParticles resetSystem];
    [menuParticles setVisible:YES];
}

-(void)fadeOutEnd
{
    [[GameManager sharedGameManager] setIsPaused:NO];
    [PopupMenu dismissPopup];
}

-(void)showPopup
{
    [[GameManager sharedGameManager] setIsPaused:YES];
    
    CCCallFunc *func = [CCCallFunc actionWithTarget:self selector:@selector(fadeInEnd)];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.15 opacity:255];
    id sequence = [CCSequence actions:fade, func, nil];
    [overlay runAction:[[fade copy] autorelease]];
    [backOverlay runAction:sequence];
    
    CGPoint topPosition = ccp(0, [[plankArray objectAtIndex:0] finalPosition].y +9+24-15);
    CGPoint bottomPosition = ccp(0, [[plankArray objectAtIndex:[plankArray count]-1] finalPosition].y -9-23.5+7);
    id topSequence = [CCSequence actions:[[fade copy] autorelease], [CCMoveTo actionWithDuration:0.15 position:topPosition], nil];
    [top runAction:topSequence];
    id bottomSequence = [CCSequence actions:[[fade copy] autorelease], [CCMoveTo actionWithDuration:0.15 position:bottomPosition], nil];
    [bottom runAction:bottomSequence];
    
    CCFadeTo *fadePlanks = [CCFadeTo actionWithDuration:0.3 opacity:255];
    for (PlankObject *plankObject in plankArray)
    {
        CGPoint final = [plankObject finalPosition];
        id spawn = [CCSpawn actions:[[fadePlanks copy] autorelease], [CCMoveTo actionWithDuration:0.15 position:final], nil];
        id sequence = [CCSequence actions:[CCDelayTime actionWithDuration:0.15], spawn, nil];
        [plankObject runAction:sequence];
    }
}

-(void)switchToMenu:(PopupType)newType
{
    CCFadeTo *listFade = [CCFadeTo actionWithDuration:0.05 opacity:0];
    id sequence = [CCSequence actions: [CCDelayTime actionWithDuration:0.05], [CCCallFunc actionWithTarget:self selector:@selector(collapsePopup)], nil];
    [currentOptions runAction:listFade];
    [self runAction:sequence];
    type = newType;
}

-(void)collapsePopup
{
    [top runAction:[CCMoveTo actionWithDuration:0.15 position:topOriginalPos]];
    [bottom runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.15 position:bottomOriginalPos], [CCCallFunc actionWithTarget:self selector:@selector(showNewMenu)],nil]];
    CCFadeTo *fadePlanks = [CCFadeTo actionWithDuration:0.15 opacity:0];
    for (PlankObject *plankObject in plankArray)
    {
        CGPoint final = ccp(0, 0);
        id spawn = [CCSpawn actions:[CCMoveTo actionWithDuration:0.15 position:final], [[fadePlanks copy] autorelease], nil];
        [plankObject runAction:spawn];
    }
}

-(void)showNewMenu
{
    [self setupMenuType];
    [self showPopup];
}

-(void)showPreviousMenu
{
    [menuStack removeLastObject];
    [self switchToMenu:[[menuStack lastObject] intValue]];
}

-(void)setVolumeChanged
{
    volumeChanged = YES;
}

-(void)hide
{
    if (volumeChanged)
    {
        [[SaveManager sharedManager] setMusicVolume:[[SimpleAudioEngine sharedEngine] backgroundMusicVolume]];
        [[SaveManager sharedManager] setSfxVolume:[[SimpleAudioEngine sharedEngine] effectsVolume]];
    }
    
    isClosing = YES;
    [top stopAllActions];
    [bottom stopAllActions];
    [overlay stopAllActions];
    [backOverlay stopAllActions];
    [currentOptions stopAllActions];
    [currentOptions setTouchEnabled:NO];

    CCCallFunc *func = [CCCallFunc actionWithTarget:self selector:@selector(fadeOutEnd)];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:0];
    id sequence = [CCSequence actions:fade, func, nil];
    
    for (PlankObject *plankObject in plankArray)
    {
        [[plankObject plank] stopAllActions];
        [plankObject runAction:[[fade copy] autorelease]];
    }
    
    [overlay runAction:[[fade copy] autorelease]];
    [backOverlay runAction:sequence];
    [top runAction:[[fade copy] autorelease]];
    [bottom runAction:[[fade copy] autorelease]];
    
    [currentOptions runAction:fade];
    [menuParticles setVisible:NO];
    [menuParticles stopSystem];
    [_popupDelegate popupDidDismiss:type];
}

-(void)setupEmitter
{
    [menuParticles removeFromParentAndCleanup:YES];
    menuParticles = [CCParticleSystemQuad particleWithFile:@"popupBacking.plist"];
    [menuParticles setPosition:ccp(0, 0)];
    [self addChild:menuParticles z:-11];
    [menuParticles setVisible:NO];
    [menuParticles stopSystem];
}

-(void)relaunch
{
    [self hide];
    [_popupDelegate relaunch];
}

-(void)goToCartCreation
{
    [self hide];
    [_popupDelegate goToCartCreation];
}

-(void)returnToLevelSelect
{
    [[GameManager sharedGameManager] playSoundEffect:@"levelSelect.mp3"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SCENE_EXIT object:nil];
    [[GameManager sharedGameManager] runSceneWithName:MainMenuSceneID];
    [PopupMenu setCurrentDisplay:nil];
}

-(void)goToSettings
{
    [self switchToMenu:kPopupSettings];
}

-(void)returnToTitle
{
    [[GameManager sharedGameManager] playSoundEffect:@"levelSelect.mp3"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SCENE_EXIT object:nil];
    [[GameManager sharedGameManager] runSceneWithName:TitleSceneID];
    [PopupMenu setCurrentDisplay:nil];
}

-(void)showTutorial
{
    InstructionLayer *instructions = [[InstructionLayer alloc] init];
    [self addChild:instructions z:100];
    [instructions setPosition:ccp(-512.0, -384.0)];
    [instructions release];
}

-(void)popupDidDismiss:(PopupType)atype
{
    [_popupDelegate popupDidDismiss:atype];
}

- (void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-1000 swallowsTouches:YES];
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(void)dealloc
{
    [plankArray release];
    plankArray = nil;
    [currentOptions release];
    currentOptions = nil;
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    [super dealloc];
}
@end
