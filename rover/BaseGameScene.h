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
-(void)setInspectionCameraEnabled:(BOOL)enabled;
-(void)panInspectionCameraBy:(CGPoint)delta;
-(void)zoomInspectionCameraBy:(CGFloat)factor;
-(void)setInspectionCameraPosition:(CGPoint)position zoom:(CGFloat)zoom;
#endif
-(void)relaunchFromKeyboard;
-(void)cartCreationFromKeyboard;
-(id)initWithPlanet:(int)pNum andLevel:(int)lNum;
@end
