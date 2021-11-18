//
//  Thingy.h
//  rover
//
//  Created by David Campbell on 5/12/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@interface Thingy : Box2DSprite
{
    b2World *world;
    CGPoint originalPosition;
    GameDirection direction;
    BOOL startDynamic;
    BOOL stopActionsAllowed;
    BOOL finishedZooming;
    CCProgressTimer *spinningTimer;
    CCProgressTimer *whachuTimer;
    CCSprite *overlay;
}

-(id)initWithWorld:(b2World *)world atLocation:(CGPoint)location startDynamic:(BOOL) dyn;
-(int)getThingyZCount;
-(void)destroyThingyPhysics;
-(void)makeDynamic;
-(void)resetThingy;
-(void)dissableSfx;

@property (nonatomic, retain) CCAnimation *deadAnim;
@property (nonatomic, retain) CCAnimation *deadLeftAnim;
@property (nonatomic, retain) CCAnimation *deadRightAnim;
@property (nonatomic, retain) CCAnimation *fallingAnim;
@property (nonatomic, retain) CCAnimation *fallingLeftAnim;
@property (nonatomic, retain) CCAnimation *fallingRightAnim;
@property (nonatomic, retain) CCAnimation *floatingAnim;
@property (nonatomic, retain) CCAnimation *floatingRightAnim;
@property (nonatomic, retain) CCAnimation *floatingLeftAnim;
@property (nonatomic, retain) CCAnimation *idleAnim;
@property (nonatomic, retain) CCAnimation *idleRightAnim;
@property (nonatomic, retain) CCAnimation *idleLeftAnim;
@property (nonatomic, retain) CCAnimation *spinAnim;
@property (nonatomic, retain) CCAnimation *spinRightAnim;
@property (nonatomic, retain) CCAnimation *spinLeftAnim;


@end
