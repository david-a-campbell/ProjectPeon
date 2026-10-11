//
//  BaseGameScene.h
//  rover
//
//  Created by David Campbell on 8/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CCScene.h"
//#import "AdManager.h"
#import "InstructionLayer.h"
@class LoadingLayer;

@interface BaseGameScene : CCScene <InstructionLayerProtocol>
{
    LoadingLayer* loadingLayer;
    int planetNum;
    int levelNum;
}
#ifdef PROJECTPEON_MAC
@property (nonatomic, readonly) BOOL inspectionCameraEnabled;
@property (nonatomic, readonly) BOOL mousePanPreviewEnabled;
-(void)setMousePanEnabled:(BOOL)enabled;
-(BOOL)canChangeMousePanState;
-(BOOL)drivingCameraAvailable;
-(void)teleportCartToScreenCenter;
-(void)panDrivingCameraBy:(CGPoint)delta;
-(void)setInspectionCameraEnabled:(BOOL)enabled;
-(void)panInspectionCameraBy:(CGPoint)delta;
-(void)zoomInspectionCameraBy:(CGFloat)factor;
-(void)setInspectionCameraPosition:(CGPoint)position zoom:(CGFloat)zoom;
#endif
#ifdef PROJECTPEON_IOS
@property(nonatomic, readonly) BOOL debugFreePanEnabled;
-(void)setDebugFreePanEnabled:(BOOL)enabled;
-(void)toggleCartCreationPan;
-(BOOL)cameraMenuContainsTouch:(UITouch *)touch;
-(BOOL)debugPanAvailable;
-(BOOL)debugPanBlocked;
-(void)panDebugCameraBy:(CGPoint)delta;
-(BOOL)debugTeleportAvailable;
-(BOOL)debugTeleportButtonContainsPoint:(CGPoint)point;
-(void)debugTeleportCart;
-(void)refreshDebugControls;
#endif
-(void)relaunchFromKeyboard;
-(void)cartCreationFromKeyboard;
-(id)initWithPlanet:(int)pNum andLevel:(int)lNum;
@end
