//
//  PlayerCart.h
//  rover
//
//  Created by David Campbell on 3/9/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"
@class CartPart;

@interface PlayerCart : Box2DSprite
{
    b2World *world;
    CGPoint originalPosition;
    CartPart* highlightedPart;
    NSMutableArray *shockDelete;
    CCProgressTimer *fuelRegenTimer;
    CGPoint positionOffset;
    float fuelLimit;
}
@property (nonatomic, strong) NSMutableArray *components;
@property (nonatomic, assign) float fuel;

- (id)initWithWorld:(b2World *)world atLocation:(CGPoint)location;
- (float32)fullMass;
-(void)createCartPhysics;
-(void)resetCartBody;
-(void)moveBodyToCart;
-(void)highlightCartPartAt:(CGPoint)highlightPoint;
-(void)deleteCartPart:(CartPart*)partToDelete;
-(void)deleteHighlightedPart;
-(void)unhighlightPart;
-(void)startCartGameplay;
-(void)dissapear;
-(void)reappear;
-(void)deleteAllCartParts;
-(void)addSwivelIndicators;
-(CGPoint)averagePosition;
-(void)applybreakableJoints;
-(void)drainFuelAmount:(int)fuelAmount;
-(BOOL)hasFuel;
-(float)maxFuel;
-(void)highlightAllParts;
-(void)unhighlightAllParts;
-(void)deleteConnectedShocks:(b2Fixture*)fixture;
-(NSArray*)componentsInOrderOfZ;
-(void)removeNonGameplayFixtures;
-(int)partCount;
-(BOOL)body:(b2Body*)aBody isWithinRadius:(float)radius;
-(CartPart*)deletePartAtLocation:(CGPoint)location  outputShocks:(NSMutableArray*)outShocks;
@end
