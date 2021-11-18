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
-(id)initWithPlanet:(int)pNum andLevel:(int)lNum;
@end
