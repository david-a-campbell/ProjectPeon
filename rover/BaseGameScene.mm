//
//  BaseGameScene.m
//  rover
//
//  Created by David Campbell on 8/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "BaseGameScene.h"
#import "BaseActionLayer.h"
#import "PlayerCart.h"
#import "CartCreationLayer.h"
#import "ForeGroundParallaxLayer.h"
#import "BacgroundParallaxLayer.h"
#import "SkyboxParallaxLayer.h"
#import "PopupMenu.h"
#import "SaveMenu.h"
#import "LoadingLayer.h"
#import "ToolTipMenu.h"
#import "GameManager.h"
#import "SaveManager.h"
#import "ControlsLayer.h"
#ifdef PROJECTPEON_MAC
#import "PeonWideScreen.h"
#import "PeonViewport.h"
#endif

@interface BaseGameScene()
{
    CartCreationLayer *creationLayer;
#ifdef PROJECTPEON_MAC
    BOOL inspectionCameraEnabled;
    BOOL mousePanPreviewEnabled;
    NSMutableArray *mousePanHiddenNodes;
    CGPoint inspectionOriginalPosition;
    CGFloat inspectionOriginalScale;
    BOOL inspectionOriginalWide;
    BOOL inspectionDirectorWasPaused;
#endif
}
@end

#ifdef PROJECTPEON_MAC
static BOOL PeonPanBlockedByMenu(CCNode *node) {
    if([node isKindOfClass:[PopupMenu class]] || [node isKindOfClass:[ToolTipMenu class]] ||
       [node isKindOfClass:[SaveMenu class]] || [node isKindOfClass:[LoadingLayer class]] ||
       [node isKindOfClass:[InstructionLayer class]]) return YES;
    for(CCNode *child in node.children) if(PeonPanBlockedByMenu(child)) return YES;
    return NO;
}
#endif

@implementation BaseGameScene

#ifdef PROJECTPEON_MAC
@synthesize inspectionCameraEnabled;
@synthesize mousePanPreviewEnabled;
-(BOOL)canChangeMousePanState {
    return !PeonPanBlockedByMenu(self);
}
-(void)setMousePanEnabled:(BOOL)enabled {
    if(![self canChangeMousePanState]) return;
    if(!enabled) {
        if(mousePanPreviewEnabled) [self setInspectionCameraEnabled:NO];
        return;
    }
    if(inspectionCameraEnabled || ![[creationLayer valueForKey:@"cartCreationEnabled"] boolValue]) return;
    BaseActionLayer *layer=[self inspectionActionLayer];
    if(!layer) return;
    [self setInspectionCameraEnabled:YES];
    mousePanPreviewEnabled=YES;
    mousePanHiddenNodes=[[NSMutableArray alloc] init];
    NSMutableArray *nodes=[NSMutableArray arrayWithArray:[layer.playerCart componentsInOrderOfZ] ?: @[]];
    [nodes addObject:creationLayer];
    // The corner menu belongs to the separate controls layer.
    CCNode *cornerMenu=[creationLayer valueForKey:@"tabMenu"];
    if(cornerMenu) [nodes addObject:cornerMenu];
    for(CCNode *node in nodes) {
        [mousePanHiddenNodes addObject:@{@"node":node,@"visible":@(node.visible)}];
        node.visible=NO;
    }
    // Keep the same world point centered while adopting the driving zoom.
    CGFloat ratio=.35/layer.scale;
    [self setInspectionCameraPosition:ccp(512+(layer.position.x-512)*ratio,
                                         384+(layer.position.y-384)*ratio) zoom:.35];
}
-(void)teleportCartToScreenCenter {
    if (mousePanPreviewEnabled || ![[NSUserDefaults standardUserDefaults] boolForKey:@"PeonTeleportCart"]) return;
    [[self inspectionActionLayer] teleportCartToScreenCenter];
}
-(BOOL)drivingCameraAvailable {
    return mousePanPreviewEnabled || (!inspectionCameraEnabled && [[self inspectionActionLayer] drivingCameraAvailable]);
}
-(void)panDrivingCameraBy:(CGPoint)delta {
    if(mousePanPreviewEnabled) [self panInspectionCameraBy:delta];
    else if([self drivingCameraAvailable]) [[self inspectionActionLayer] panDrivingCameraBy:delta];
}
-(BaseActionLayer *)inspectionActionLayer {
    for(CCNode *node in self.children) if([node isKindOfClass:[BaseActionLayer class]]) return (BaseActionLayer *)node;
    return nil;
}
-(void)setInspectionCameraEnabled:(BOOL)enabled {
    BaseActionLayer *layer=[self inspectionActionLayer];
    if(!layer || enabled==inspectionCameraEnabled) return;
    inspectionCameraEnabled=enabled;
    if(enabled) {
        inspectionOriginalPosition=layer.position;
        inspectionOriginalScale=layer.scale;
        inspectionOriginalWide=PeonWideScreenAmount()>0;
        inspectionDirectorWasPaused=[[CCDirector sharedDirector] isPaused];
        [[CCDirector sharedDirector] pause];
        [[PeonWideScreen sharedPresentation] setDriving:YES];
    } else {
        if(mousePanPreviewEnabled) {
            for(NSDictionary *state in mousePanHiddenNodes) [(CCNode *)state[@"node"] setVisible:[state[@"visible"] boolValue]];
            [mousePanHiddenNodes release]; mousePanHiddenNodes=nil;
            mousePanPreviewEnabled=NO;
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PeonMousePan"];
        }
        [[PeonWideScreen sharedPresentation] setDriving:inspectionOriginalWide];
        layer.scaleX=inspectionOriginalScale;
        layer.scaleY=inspectionOriginalScale;
        layer.position=inspectionOriginalPosition;
        if(!inspectionDirectorWasPaused) [[CCDirector sharedDirector] resume];
    }
}
-(void)setInspectionCameraPosition:(CGPoint)position zoom:(CGFloat)zoom {
    if(!inspectionCameraEnabled) return;
    BaseActionLayer *layer=[self inspectionActionLayer];
    CGFloat clampedZoom=MAX(.2,MIN(1,zoom));
    layer.scaleX=clampedZoom;
    layer.scaleY=clampedZoom;
    CGFloat width=[[layer valueForKey:@"mapWidth"] doubleValue];
    CGFloat inset=(PeonPresentationSize([CCDirector sharedDirector].winSize).width-[CCDirector sharedDirector].winSize.width)/2;
    position.x=MAX(position.x,-width*layer.scale+1024+256*layer.scale+inset);
    position.y=MIN(position.y,-256*layer.scale);
    if(mousePanPreviewEnabled) {
        CGFloat height=[[layer valueForKey:@"mapHeight"] doubleValue];
        position.x=MIN(position.x,-256*layer.scale-inset);
        position.y=MAX(position.y,-height*layer.scale+768);
    }
    layer.position=position;
}
-(void)panInspectionCameraBy:(CGPoint)delta {
    BaseActionLayer *layer=[self inspectionActionLayer];
    [self setInspectionCameraPosition:ccpAdd(layer.position,delta) zoom:layer.scale];
}
-(void)zoomInspectionCameraBy:(CGFloat)factor {
    BaseActionLayer *layer=[self inspectionActionLayer];
    CGFloat zoom=MAX(.2,MIN(1,layer.scale*factor));
    CGFloat ratio=zoom/layer.scale;
    [self setInspectionCameraPosition:ccp(512+(layer.position.x-512)*ratio,384+(layer.position.y-384)*ratio) zoom:zoom];
}
#endif

-(void)cartCreationFromKeyboard
{
#ifdef PROJECTPEON_MAC
    if(mousePanPreviewEnabled) { if([self canChangeMousePanState]) [self setInspectionCameraEnabled:NO]; return; }
#endif
    for (CCNode *child in self.children)
        if ([child isKindOfClass:[PopupMenu class]]) return;
    [creationLayer cartCreationFromKeyboard];
}

-(void)relaunchFromKeyboard
{
    for (CCNode *child in self.children)
        if ([child isKindOfClass:[PopupMenu class]]) return;
    [creationLayer relaunchFromKeyboard];
}


-(id)initWithPlanet:(int)pNum andLevel:(int)lNum
{
    self = [super init];
    if (self)
    {
        planetNum = pNum;
        levelNum = lNum;
        
        if ([[SaveManager sharedManager] getShowTutorialState])
        {
            InstructionLayer *instructions = [[InstructionLayer alloc] init];
            [instructions setDelegate:self];
            [self addChild:instructions z:7];
            [instructions release];
        }else
        {
            [self displayLoadingScreen];
        }
    }
    return self;
}

-(void)instructionsWillBeRemoved
{
    [self displayLoadingScreen];
}

-(void)displayLoadingScreen
{
    loadingLayer = [[LoadingLayer alloc] initWithPlanetNum:planetNum LevelNumber:levelNum];
    [self addChild:loadingLayer z:90000];
    [loadingLayer release];
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1], [CCCallFunc actionWithTarget:self selector:@selector(setupWorld)], nil]];
}

-(void)setupWorld
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"menuItemsAtlas.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"spriteAtlas.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"spriteAtlas2.plist"];
    
    CGPoint tmxMapping = [[GameManager sharedGameManager] currentTmxMaping];
    int tmxPNum = tmxMapping.x;
    int tmxLNum = tmxMapping.y;
    
    NSString *tmxName = [NSString stringWithFormat:@"planet%iLevel%i.tmx", tmxPNum, tmxLNum];
    NSString *animSpriteFrames = [NSString stringWithFormat:@"Planet%i_AnimatedSprites.plist", tmxPNum];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile: animSpriteFrames];
    
    BaseActionLayer *actionLayer = [[BaseActionLayer alloc] initWithTileMapName:tmxName];
    ControlsLayer *controlsLayer = [[ControlsLayer alloc] init];
    creationLayer = [[CartCreationLayer alloc] initwithLayerToFollow:actionLayer andDelegate:actionLayer topLayer:controlsLayer];
    ForeGroundParallaxLayer *fgLayer = [[ForeGroundParallaxLayer alloc] initWithTileMap:[actionLayer TileMapName]];
    BacgroundParallaxLayer *bgLayer = [[BacgroundParallaxLayer alloc] initWithTileMap:[actionLayer TileMapName]];
    SkyboxParallaxLayer *sbLayer = [[SkyboxParallaxLayer alloc] initWithTileMap:[actionLayer TileMapName]];
    
    [actionLayer setControlsDelegate:controlsLayer];
    [controlsLayer setActionLayer:actionLayer];
    
    [actionLayer addParallaxLayer:fgLayer];
    [actionLayer addParallaxLayer:bgLayer];
    [actionLayer addParallaxLayer:sbLayer];
    
    [self addChild:sbLayer z:0];
    [self addChild:bgLayer z:1];
    [self addChild:actionLayer z:2];
    [self addChild:fgLayer z:3];
    [self addChild:creationLayer z:4];
    [self addChild:[creationLayer levelScoreDisplay] z:5];
    [self addChild:controlsLayer z:6];
    
    [actionLayer setPosition:[actionLayer position]];
    
    [controlsLayer release];
    [creationLayer release];
    [actionLayer release];
    [fgLayer release];
    [bgLayer release];
    [sbLayer release];
    [self loadComplete];
}

-(void)loadComplete
{    
    [self runAction:[CCSequence actions:[loadingLayer fadeOutSequence], [CCCallFunc actionWithTarget:self selector:@selector(removeLoadingLayer)], nil]];
}

-(void)removeLoadingLayer
{
#ifdef PROJECTPEON_MAC
    [[PeonWideScreen sharedPresentation] setCartCreation:YES];
#endif
    [loadingLayer removeFromParentAndCleanup:YES];
    loadingLayer = nil;
//    [[AdManager sharedAdManager] setShouldDisplayInterstitialAd:NO];
}

-(void)onExit
{
#ifdef PROJECTPEON_MAC
    if(inspectionCameraEnabled) [self setInspectionCameraEnabled:NO];
#endif
    [super onExit];
}

-(void)dealloc
{
#ifdef PROJECTPEON_MAC
    [mousePanHiddenNodes release];
#endif
    [super dealloc];
}

@end

