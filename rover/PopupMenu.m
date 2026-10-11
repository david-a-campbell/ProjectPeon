//
//  popupMenu.m
//  rover
//
//  Created by David Campbell on 5/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "PopupMenu.h"
#import "../mac/PeonCloseButton.h"
#ifdef PROJECTPEON_IOS
@implementation PeonCloseMenu
-(void)registerWithTouchDispatcher {
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:self.closePriority swallowsTouches:YES];
}
@end
#endif
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

#ifdef PROJECTPEON_IOS
#import "PeonIOSDebug.h"
#import "BaseGameScene.h"
#import "ToolTipMenu.h"
#import "SaveMenu.h"
#import "../mac/PeonDebugSettings.h"

static BOOL PeonDebugHasModal(CCNode *node) {
    if ([node isKindOfClass:[PopupMenu class]] || [node isKindOfClass:[ToolTipMenu class]] ||
        [node isKindOfClass:[SaveMenu class]] || [node isKindOfClass:[InstructionLayer class]]) return YES;
    for (CCNode *child in node.children) if (PeonDebugHasModal(child)) return YES;
    return NO;
}
static CCLabelBMFont *PeonDebugLabel(NSString *text) {
    CCLabelBMFont *label=[CCLabelBMFont labelWithString:text fntFile:@"font42.fnt"];
    label.scale=1;
    for (CCSprite *glyph in label.children) {
        CGRect rect=glyph.textureRect; CGSize size=glyph.contentSize;
        [glyph setTextureRect:CGRectInset(rect,.5,.5) rotated:glyph.textureRectRotated untrimmedSize:size];
    }
    return label;
}
static void PeonDebugCenterItem(CCMenuItemLabel *item) {
    CCLabelBMFont *label=(id)item.label;
    item.contentSize=CGSizeMake(label.contentSize.width*label.scale+24,80);
    label.anchorPoint=ccp(.5,.5); label.position=ccp(item.contentSize.width/2,40);
}
@interface PeonDebugPopup : BasePopupMenu {
    CCMenu *options;
}
-(void)refresh;
@end
@implementation PeonDebugPopup
-(void)createMenu {
    CCLabelBMFont *title=PeonDebugLabel(@"DEBUG"); title.scale=1.2; title.position=ccp(0,255);
    [self.nodeArray addObject:title];
    options=[CCMenu menuWithItems:nil]; options.position=CGPointZero;
    NSArray *keys=@[@"PeonHideFPS",@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonUnlockAllLevels",@"PeonFreePan",@"PeonTeleportCart"];
    for (NSUInteger index=0;index<keys.count;index++) {
        CCMenuItemLabel *item=[CCMenuItemLabel itemWithLabel:PeonDebugLabel(@" ") target:self selector:@selector(toggleOption:)];
        item.tag=index; item.position=ccp(0,200-(NSInteger)index*80); [options addChild:item];
    }
    [self.nodeArray addObject:options];
    CCLabelTTF *hint=[CCLabelTTF labelWithString:@"Teleport: free pan while driving, then tap boost." fontName:@"Helvetica" fontSize:18];
    hint.position=ccp(0,-255); [self.nodeArray addObject:hint];
    [self refresh];
}
-(int)numberOfPlanks { return 32; }
-(void)refresh {
    NSArray *keys=@[@"PeonHideFPS",@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonUnlockAllLevels",@"PeonFreePan",@"PeonTeleportCart"];
    NSArray *names=@[@"Show FPS",@"Show Box2D Objects",@"Disable Ship Finish Trigger",@"Unlock All Levels",@"Free Pan Map (2x)",@"Enable Cart Teleport"];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    BaseGameScene *scene=[[CCDirector sharedDirector].runningScene isKindOfClass:[BaseGameScene class]] ? (id)[CCDirector sharedDirector].runningScene : nil;
    for (CCMenuItemLabel *item in options.children) {
        BOOL on=[defaults boolForKey:keys[item.tag]]; if (item.tag==0) on=!on;
        [(CCLabelBMFont *)item.label setString:[NSString stringWithFormat:@"%@  %@",on ? @"[x]" : @"[ ]",names[item.tag]]];
        for (CCSprite *glyph in item.label.children) {
            CGRect rect=glyph.textureRect; CGSize size=glyph.contentSize;
            [glyph setTextureRect:CGRectInset(rect,.5,.5) rotated:glyph.textureRectRotated untrimmedSize:size];
        }
        PeonDebugCenterItem(item);
        item.isEnabled=item.tag==4 ? [scene debugPanAvailable] : (item.tag==5 ? [scene debugFreePanEnabled] : YES);
    }
}
-(void)toggleOption:(CCMenuItemLabel *)item {
    NSArray *keys=@[@"PeonHideFPS",@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonUnlockAllLevels",@"PeonFreePan",@"PeonTeleportCart"];
    if (item.tag==4) {
        [(PopupMenu *)self.popupDelegate hide];
        [(PeonIOSDebugLayer *)[[CCDirector sharedDirector].runningScene getChildByTag:9930] performSelector:@selector(toggleFreePan) withObject:nil afterDelay:.3];
        return;
    }
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *key=keys[item.tag]; [defaults setBool:![defaults boolForKey:key] forKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PeonDebugOptionsChanged" object:nil];
    [self refresh];
}
@end

// Debug navigation crosses planet boundaries, without marking levels complete.
static BOOL PeonDebugAdjacentLevel(int planet,int level,int step,int *nextPlanet,int *nextLevel) {
    static NSArray *levelCounts=nil;
    if (!levelCounts) {
        SaveManager *save=[SaveManager sharedManager]; NSMutableArray *counts=[NSMutableArray array];
        for(int p=1;p<=[save numberOfPlanets];p++) [counts addObject:@([save numberOfLevelsForPlanetNumber:p])];
        levelCounts=[counts copy];
    }
    if(planet<1 || planet>(int)levelCounts.count || level<1 || level>[levelCounts[planet-1] intValue]) return NO;
    int target=level+step;
    if (target<1) { planet--; if(planet<1) return NO; target=[levelCounts[planet-1] intValue]; }
    else if(target>[levelCounts[planet-1] intValue]) { planet++; if(planet>(int)levelCounts.count) return NO; target=1; }
    *nextPlanet=planet; *nextLevel=target; return YES;
}

@implementation PeonIOSDebugLayer
-(id)init {
    if ((self=[super init])) {
        CCMenuItemLabel *entry=[CCMenuItemLabel itemWithLabel:PeonDebugLabel(@"Debug") target:self selector:@selector(openDebug)];
        PeonDebugCenterItem(entry);
        debugBacking=[CCLayerColor layerWithColor:ccc4(0,0,0,160) width:160 height:80];
        CGSize canvas=[[CCDirector sharedDirector] winSize];
        CGPoint debugCorner=ccp(-canvas.width/6,canvas.height-80);
        debugBacking.position=debugCorner; debugBacking.visible=NO; [self addChild:debugBacking];
        debugEntry=[CCMenu menuWithItems:entry,nil]; debugEntry.position=ccp(debugCorner.x+80,debugCorner.y+40); debugEntry.visible=NO;
        [self addChild:debugEntry];
        NSMutableArray *navigationItems=[NSMutableArray array];
        for (NSString *title in @[@"Next Level",@"Previous Level"]) {
            CCLabelTTF *label=[CCLabelTTF labelWithString:title fontName:@"Helvetica-Bold" fontSize:20];
            label.scale=MIN(1,136/label.contentSize.width);
            CCMenuItemLabel *item=[CCMenuItemLabel itemWithLabel:label target:self selector:@selector(changeLevel:)];
            item.tag=navigationItems.count==0 ? 1 : 2;
            item.contentSize=CGSizeMake(160,80);
            label.anchorPoint=ccp(.5,.5); label.position=ccp(80,40);
            item.position=ccp(0,-80*(NSInteger)navigationItems.count);
            [navigationItems addObject:item];
        }
        navigationBacking=[CCLayerColor layerWithColor:ccc4(0,0,0,160) width:160 height:160];
        navigationBacking.position=ccp(debugCorner.x,debugCorner.y-160); navigationBacking.visible=NO;
        [self addChild:navigationBacking];
        levelNavigation=[CCMenu menuWithArray:navigationItems];
        levelNavigation.position=ccp(debugCorner.x+80,debugCorner.y-40); levelNavigation.visible=NO;
        [self addChild:levelNavigation];
        toastBacking=[CCLayerColor layerWithColor:ccc4(0,0,0,210) width:360 height:56];
        toastBacking.position=ccp(332,662); toastBacking.visible=NO; [self addChild:toastBacking z:1];
        toast=[CCLabelTTF labelWithString:@"" fontName:@"Helvetica-Bold" fontSize:28];
        toast.position=ccp(512,690); toast.visible=NO; [self addChild:toast z:2];
        self.touchEnabled=YES; [self scheduleUpdate];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleDebug:) name:@"PeonToggleDebugMenu" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionsChanged) name:@"PeonDebugOptionsChanged" object:nil];
    }
    return self;
}
-(void)onEnter {
    [super onEnter];
    [debugEntry setHandlerPriority:-950];
    [levelNavigation setHandlerPriority:-950];
#if DEBUG
    if ([[NSProcessInfo processInfo].environment[@"PEON_DEBUG_NAV_AUDIT"] boolValue]) {
        static BOOL launchedNavigation=NO;
        if ([self gameScene]) [self performSelector:@selector(debugNavigationAudit) withObject:nil afterDelay:4];
        else if(!launchedNavigation && [NSStringFromClass(self.parent.class) isEqualToString:@"TitleScene"]) {
            launchedNavigation=YES;
            [self performSelector:@selector(launchCameraAudit) withObject:nil afterDelay:.5];
        }
    }
    BOOL savePanAudit=[[NSProcessInfo processInfo].environment[@"PEON_SAVE_MENU_PAN_AUDIT"] boolValue];
    if ([[NSProcessInfo processInfo].environment[@"PEON_DEBUG_CAMERA_AUDIT"] boolValue] || savePanAudit) {
        static BOOL launched=NO;
        if ([self gameScene]) [[self gameScene] performSelector:savePanAudit ? @selector(debugSaveMenuPanAudit) : @selector(debugCameraAudit) withObject:nil afterDelay:3];
        else if (!launched && [NSStringFromClass(self.parent.class) isEqualToString:@"TitleScene"]) {
            launched=YES; [self performSelector:@selector(launchCameraAudit) withObject:nil afterDelay:.5];
        }
    }
#endif
}
#if DEBUG
-(void)debugNavigationAudit {
    static int phase=0;
    static id savedDebug=nil;
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    GameManager *game=[GameManager sharedGameManager];
    if(phase>=3) return;
    if(phase==0) {
        savedDebug=[[defaults objectForKey:@"PeonDebugMenuVisible"] retain];
        int planet,level;
        NSCAssert(!PeonDebugAdjacentLevel(1,1,-1,&planet,&level),@"Previous escaped Earth 01");
        int earthEnd=[[SaveManager sharedManager] numberOfLevelsForPlanetNumber:1];
        NSCAssert(PeonDebugAdjacentLevel(1,earthEnd,1,&planet,&level) && planet==2 && level==1,@"Next did not cross planets");
        NSCAssert(PeonDebugAdjacentLevel(2,1,-1,&planet,&level) && planet==1 && level==earthEnd,@"Previous did not cross planets");
        int lastPlanet=[[SaveManager sharedManager] numberOfPlanets];
        NSCAssert(!PeonDebugAdjacentLevel(lastPlanet,[[SaveManager sharedManager] numberOfLevelsForPlanetNumber:lastPlanet],1,&planet,&level),@"Next escaped the last level");
    }
    [defaults setBool:YES forKey:@"PeonDebugMenuVisible"]; [self update:0];
    NSCAssert(levelNavigation.visible && navigationBacking.visible,@"Level buttons missing during building");
    if(phase==0 || phase==1) {
        NSCAssert(game.currentPlanetNum==1 && game.currentLevelNum==(phase==0 ? 1 : 2),@"Level button loaded wrong map");
        CCMenuItemLabel *item=(id)[levelNavigation getChildByTag:phase==0 ? 1 : 2];
        phase++;
        [self changeLevel:item]; return;
    }
    NSCAssert(game.currentPlanetNum==1 && game.currentLevelNum==1,@"Previous did not return to Earth 01");
    [[self gameScene] setDebugFreePanEnabled:YES]; [self update:0];
    NSCAssert(levelNavigation.visible,@"Free pan hid level navigation");
    [[self gameScene] setDebugFreePanEnabled:NO];
    [defaults setBool:NO forKey:@"PeonDebugMenuVisible"]; [self update:0];
    NSCAssert(!levelNavigation.visible,@"Navigation remained visible with debug off");
    if(savedDebug) [defaults setObject:savedDebug forKey:@"PeonDebugMenuVisible"]; else [defaults removeObjectForKey:@"PeonDebugMenuVisible"];
    [savedDebug release]; savedDebug=nil; phase++;
    [self update:0];
    fprintf(stderr,"PEON_DEBUG_NAV_AUDIT_PASS: real next/previous launches, planet boundaries, build/free-pan visibility, debug-off hiding\n");
}
-(void)launchCameraAudit {
    SaveManager *save=[SaveManager sharedManager]; BOOL tutorial=[save getShowTutorialState];
    [save setShowTutorialState:NO];
    GameManager *manager=[GameManager sharedGameManager]; manager.currentPlanetNum=1; manager.currentLevelNum=1;
    [manager runPlanet:1 level:1];
    [save setShowTutorialState:tutorial];
}
#endif
-(BaseGameScene *)gameScene { return [self.parent isKindOfClass:[BaseGameScene class]] ? (id)self.parent : nil; }
-(void)showToast:(NSString *)message {
    toast.string=message; toast.visible=YES; toast.opacity=255; [toast stopAllActions];
    toastBacking.visible=YES; toastBacking.opacity=210; [toastBacking stopAllActions];
    [toastBacking runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.8],[CCFadeOut actionWithDuration:.3],nil]];
    [toast runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.8],[CCFadeOut actionWithDuration:.3],nil]];
}
-(void)toggleDebug:(NSNotification *)notification {
    if (!PeonDebugBuildEnabled() || self.parent!=[CCDirector sharedDirector].runningScene) return;
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    BOOL visible=![defaults boolForKey:@"PeonDebugMenuVisible"];
    PeonSetDebugMenuVisible(defaults,visible);
    if (!visible) [[self gameScene] setDebugFreePanEnabled:NO];
    [self optionsChanged]; [self showToast:visible ? @"Debug ON" : @"Debug OFF"];
}
-(void)optionsChanged {
    [[CCDirector sharedDirector] setDisplayStats:![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonHideFPS"]];
    [[self gameScene] refreshDebugControls];
}
-(void)openDebug {
    if (!PeonDebugBuildEnabled() || ![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonDebugMenuVisible"] || PeonDebugHasModal(self.parent)) return;
    [PopupMenu showPopupMenuType:kPopupDebug withDelegate:nil];
}
-(void)changeLevel:(CCMenuItemLabel *)sender {
    BaseGameScene *scene=[self gameScene];
    if (navigatingLevel || !levelNavigation.visible || ![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonDebugMenuVisible"] || ![scene debugPanAvailable] || [scene valueForKey:@"loadingLayer"] || PeonDebugHasModal(self.parent)) return;
    GameManager *game=[GameManager sharedGameManager]; int planet,level;
    if(!PeonDebugAdjacentLevel(game.currentPlanetNum,game.currentLevelNum,sender.tag==1 ? 1 : -1,&planet,&level)) return;
    navigatingLevel=YES; panTouch=nil;
    [scene setDebugFreePanEnabled:NO];
    game.currentPlanetNum=planet; game.currentLevelNum=level;
    game.isPaused=NO;
    [game runPlanet:planet level:level];
}
-(void)toggleFreePan {
    BaseGameScene *scene=[self gameScene];
    [scene setDebugFreePanEnabled:!scene.debugFreePanEnabled];
    [self showToast:scene.debugFreePanEnabled ? @"Free Pan ON" : @"Follow Cart"];
}
-(void)update:(ccTime)delta {
    debugEntry.visible=PeonDebugBuildEnabled() && [[NSUserDefaults standardUserDefaults] boolForKey:@"PeonDebugMenuVisible"] && !PeonDebugHasModal(self.parent);
    debugBacking.visible=debugEntry.visible;
    BaseGameScene *scene=[self gameScene];
    levelNavigation.visible=debugEntry.visible && !navigatingLevel && [scene debugPanAvailable] && ![scene valueForKey:@"loadingLayer"];
    navigationBacking.visible=levelNavigation.visible;
    GameManager *game=[GameManager sharedGameManager];
    for (CCMenuItemLabel *item in levelNavigation.children) {
        int planet,level;
        item.isEnabled=PeonDebugAdjacentLevel(game.currentPlanetNum,game.currentLevelNum,item.tag==1 ? 1 : -1,&planet,&level);
    }
    if (scene.debugFreePanEnabled && ![scene debugPanAvailable]) [scene setDebugFreePanEnabled:NO];
}
-(void)registerWithTouchDispatcher {
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-900 swallowsTouches:YES];
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    BaseGameScene *scene=[self gameScene];
    if (!scene.debugFreePanEnabled || [scene debugPanBlocked]) return NO;
    // Let the regular menu remain reachable so the player can leave camera preview.
    if ([scene cameraMenuContainsTouch:touch]) return NO;
    CGPoint point=[self convertTouchToNodeSpace:touch];
    if ([scene debugTeleportButtonContainsPoint:point]) { [scene debugTeleportCart]; return YES; }
    if (!panTouch) { panTouch=touch; previousPanPoint=point; }
    return YES;
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch!=panTouch) return;
    CGPoint point=[self convertTouchToNodeSpace:touch];
    [[self gameScene] panDebugCameraBy:ccpSub(point,previousPanPoint)]; previousPanPoint=point;
}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event { if (touch==panTouch) panTouch=nil; }
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event { [self ccTouchEnded:touch withEvent:event]; }
-(void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [NSObject cancelPreviousPerformRequestsWithTarget:self]; [super dealloc]; }
@end
#endif

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
    overlay = [CCSprite spriteWithFile:@"MenuGridWide.png"];
    backOverlay = [CCSprite spriteWithFile:@"darkOverlay93.png"];
    
    [top setScale:2*SCREEN_SCALE];
    [bottom setScale:2*SCREEN_SCALE];
    [overlay setScale:2*(SCREEN_SCALE)];
    [backOverlay setScale:2*(SCREEN_SCALE)];
#ifdef PROJECTPEON_WIDE_UI
    [overlay setScaleX:(1024.0*4/3)/overlay.contentSize.width];
    [overlay setScaleY:768.0/overlay.contentSize.height];
    [backOverlay setScaleX:(1024.0*4/3)/backOverlay.contentSize.width];
#else
    overlay.scaleX=1024.0/overlay.contentSize.width;
    overlay.scaleY=768.0/overlay.contentSize.height;
#endif
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
    PeonAddCloseButton(top, [self isWide], self, @selector(hide), -1002);
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
#ifdef PROJECTPEON_IOS
        case kPopupDebug:
            if (!PeonDebugBuildEnabled()) return nil;
            return [[[PeonDebugPopup alloc] initWithDelegate:self] autorelease];
#endif
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
#ifdef PROJECTPEON_MAC
    return [[menuStack objectAtIndex:0] intValue] == kPopupTypeGamePlay;
#else
    return ([[menuStack objectAtIndex:0] intValue] == kPopupTypeCartCreation || [[menuStack objectAtIndex:0] intValue] == kPopupTypeGamePlay);
#endif
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
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CGRect boundingBox = CGRectUnion(top.boundingBox, bottom.boundingBox);

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
    PeonDisableCloseButton(top);
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
