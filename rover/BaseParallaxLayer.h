//
//  BaseParallaxLayer.h
//  rover
//
//  Created by David Campbell on 6/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "GLES-Render.h"
#import "Constants.h"
#import "CommonProtocols.h"
@class PunkParallax;

@interface BaseParallaxLayer : CCLayer
{
    CCTMXTiledMap *tileMapNode;
    CGPoint originalPosition;
    float mapWidth;
    float mapHeight;
    float mapTime;
    float placeHolderZOrder;
    CCTMXMapInfo *mapInfo;
    NSString *_tileMapName;
    PunkParallax *parrallaxNode;
}
-(id)initWithTileMapName:(NSString*)tileMapName;
-(void)setupParallaxLayers;
//-(void)setupLayer:(CCTMXLayer*)layer;
-(void)processLayerPlaceholderGroup:(CCTMXObjectGroup*)layerPlaceHolderGroup;
-(void) processCollisionGroup:(CCTMXObjectGroup*)collisionObjects;
-(void)processSpriteGroup:(CCTMXObjectGroup*)spriteGroup;

//Creation
-(void)createThingySpriteAtLocation:(CGPoint)location dynamic:(BOOL)dyn;
-(void)setParallaxPosition:(CGPoint)position;
-(void)setParallaxScaleY:(float)scaleY;
-(void)setParallaxScaleX:(float)scaleX;
@end
