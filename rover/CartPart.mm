//
//  cartPart.m
//  rover
//
//  Created by David Campbell on 3/10/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartPart.h"
#import "Box2DHelpers.h"
#import "PlayerCart.h"

@implementation CartPart

@synthesize friction, restitution, density, categoryBits, maskBits, groupIndex, zOrder;
@synthesize fixture, world, cart, start, end, isReadyForRemoval, cartPartModifier;

-(id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart *)theCart
{
    if(self = [super init])
    {
        friction = 0.3;
        restitution = 0.1;
        density = 5000.0;
        categoryBits = kLayer1Cat;
        maskBits = kCollideAllMask;
        groupIndex = 0;
        start = touchStartLocation;
        end = touchEndLocation;
        if (theCart)
        {
            world = theCart.body->GetWorld();
        }
        cart = theCart;
        [[cart components] addObject:self];
        body = nil;
        isReadyForRemoval = NO;
        [self setIsInForeground:NO];
        originalColor = [self color];
        highlightedColor = ccRED;
        cartPartModifier = kStandardPart;
        [self setPositionOffset:b2Vec2(0,0)];
    }
    return self;
}

-(void)setIsInForeground:(BOOL)fg
{
    _isInForeground = fg;
}

-(int)zOrder
{
    if (gameObjectType == kShockPartType && _isInForeground)
    {
        return 400;
    }
    if (gameObjectType == kShockPartType && !_isInForeground)
    {
        return 150;
    }
    
    int zOrderToReturn = 100;
    
    if(categoryBits == kLayer1Cat)
    {
        zOrderToReturn = 100;
    }
    if (categoryBits == kLayer2Cat)
    {
        zOrderToReturn = 200;
    }
    if (categoryBits == kLayer3Cat)
    {
        zOrderToReturn = 300;
    }
    
    if (gameObjectType == kBoosterPartType || gameObjectType == kBooster50PartType)
    {
        zOrderToReturn += 5;
    }
    
    return zOrderToReturn;
}

-(void)resetPart;
{
    body = nil;
    [self setIsInForeground:NO];
    [self setZOrder:[self zOrder]];
}

-(void)dealloc
{
    fixture = nil;
    world = nil;
    cart = nil;
    body = nil;
    [super dealloc];
}

-(void)highlightMe
{
    [self setColor:highlightedColor];
}

-(void)unHighlightMe
{
    [self setColor:originalColor];
}

-(void)dissapear
{
    [self setOpacity:0];
    for (CCSprite *partImage in [self children])
    {
        [partImage setOpacity:0];
    }
}

-(void)reappear
{
    CCFadeTo *fade = [CCFadeTo actionWithDuration:1.5 opacity:255];
    [self runAction:[[fade copy] autorelease]];
    for (CCSprite *partImage in [self children])
    {
        [partImage runAction:[[fade copy] autorelease]];
    }
}

-(b2FixtureDef)createFixtureDef
{
    NSAssert(false, @"should be implemented in child");
    b2FixtureDef nothing;
    return nothing;
}

-(b2Shape*)createShape
{
    NSAssert(false, @"should be implemented in child");
    return nil;
}

-(b2Shape*)createShapeForCenter:(b2Vec2)center
{
    NSAssert(false, @"should be implemented in child");
    return nil;
}

-(void)removeFromParentAndCleanup:(BOOL)cleanup
{
    fixture = nil;
    world = nil;
    cart = nil;
    body = nil;
    [super removeFromParentAndCleanup:cleanup];
}

-(void)destroyExtraFixtures
{
    //implement in subclass
}

-(void)setSnapshotPosition:(CGPoint)position
{
    [super setPosition:position];
}

@end
