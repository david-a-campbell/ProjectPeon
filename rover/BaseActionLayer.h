//
//  BaseActionLayer.h
//  rover
//
//  Created by David Campbell on 3/3/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "Constants.h"
#import "CommonProtocols.h"
#import "BaseParallaxLayer.h"
#import "ControlsDelegate.h"
#import "JoystickDelegate.h"
#import "ContactListner.h"

@class Box2DSprite;
@class PlayerCart;
@class Ground;

@class Cart;

@interface BaseActionLayer : BaseParallaxLayer <cartCreationDelegate, JoystickDelegate>
{
    NSString *tileMapName;
    b2World * world;
    b2Draw * debugDraw;
    b2Body *offscreenSensorBody;
    CCArray *accelerationArray;
    CCArray *touchArray;
    CCArray *morphGroundArray;
    CCArray *parallaxHolderArray;
    BOOL shouldFollowSprite;
    BOOL levelWasCompleted;
    CCRenderTexture *saveCartRender;
    CGPoint resetPosition;
    NSMutableArray *playerVelocities;
    ContactListner *contactListner;
}
@property (nonatomic, assign) NSObject<ControlsDelegate> *controlsDelegate;
@property (nonatomic, retain) PlayerCart* playerCart;
-(NSString*)TileMapName;
-(b2World*)getWorld;
-(void)addParallaxLayer:(BaseParallaxLayer*)layer;
- (id)initWithTileMapName:(NSString *)tileMap;
@end
