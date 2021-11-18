//
//  cartPart.h
//  rover
//
//  Created by David Campbell on 3/10/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@class PlayerCart;
@interface CartPart : Box2DSprite
{
    b2World *world;
    PlayerCart *cart;
    b2Fixture *fixture;
    float friction;
    float restitution;
    float density;   
    int categoryBits;
    int maskBits;
    int groupIndex;
    CGPoint start;
    CGPoint end;
    BOOL isReadyForRemoval;
    ccColor3B originalColor;
    ccColor3B highlightedColor;
}
@property (nonatomic, assign) int zOrder;
@property (nonatomic, assign) BOOL isReadyForRemoval;
@property (nonatomic, assign) BOOL isInForeground;
@property (nonatomic, assign) b2Fixture *fixture;
@property (nonatomic, assign) PlayerCart *cart;
@property (nonatomic, assign) b2World *world;
@property (nonatomic, assign) CGPoint start;
@property (nonatomic, assign) CGPoint end;
@property (nonatomic, assign) b2Vec2 positionOffset;
@property (nonatomic, assign) CartPartModifier cartPartModifier;
@property (nonatomic, assign) float friction;
@property (nonatomic, assign) float restitution;
@property (nonatomic, assign) float density;   
@property (nonatomic, assign) int categoryBits;
@property (nonatomic, assign) int maskBits;
@property (nonatomic, assign) int groupIndex;
-(void)resetPart;
-(void)highlightMe;
-(void)unHighlightMe;
-(id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart *)theCart;
-(void)dissapear;
-(void)reappear;
-(b2FixtureDef)createFixtureDef;
-(b2Shape*)createShapeForCenter:(b2Vec2)center;
-(b2Shape*)createShape;
-(void)destroyExtraFixtures;
-(void)setSnapshotPosition:(CGPoint)position;

@end
