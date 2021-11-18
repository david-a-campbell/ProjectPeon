//
//  Motor.m
//  rover
//
//  Created by David Campbell on 3/11/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Motor.h"
#import "Ground.h"
#import "SimpleQueryCallback.h"
#import "Box2DHelpers.h"

#define MAX_REVS_SEC 0.7f
#define MAX_REVS_SEC_UPGRADE 1.05
#define TORQUE 300.0f
#define TORQUE_UPGRADE 450.0f

@implementation Motor

-(id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart *)theCart andType:(GameObjectType)type
{
    if (self = [super initWithStart:touchStartLocation andEnd:touchEndLocation andCart:theCart andType:type])
    {
        if (type == kMotorPartType)
        {
            torque = TORQUE;
            maxRevsSec = MAX_REVS_SEC;
        }else if (type == kMotor50PartType)
        {
            torque = TORQUE_UPGRADE;
            maxRevsSec = MAX_REVS_SEC_UPGRADE;
        }
    }
    return self;
}

-(void)dealloc
{
    [MotorHub release];
    MotorHub = nil;
    [super dealloc];
}

-(float)restitution
{
    return 0.5;
}

-(void)setRotation:(float)rotation
{
    [super setRotation:rotation];
    [MotorHub setRotation:-rotation-rotationOffset];
}

-(void)setupImage
{
    if (gameObjectType == kMotorPartType)
    {
        [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTire.png"]];
        MotorHub = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelHub.png"]];
    }else if(gameObjectType == kMotor50PartType)
    {
        [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTireUpgrade.png"]];
        CCAnimation *animation = [self loadPlistForAnimationWithName:@"pulse" andClassName:@"wheelUpgrade"];
        MotorHub = [[CCSprite alloc] init];
        id repeat = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:animation]];
        [MotorHub runAction:repeat];
    }
    

    [self addChild:MotorHub];
    [MotorHub setPosition:ccp([self boundingBox].size.height/2.0f,[self boundingBox].size.width/2.0f)];
    [self addPivotIndicator];
    
    [self setPosition:start];
    float diameter = ccpDistance(start, end)*2.0f;
    [self setScale:diameter/[self boundingBox].size.height];
    rotationOffset = -[self pointPairToBearingDegrees:start secondPoint:end];
}

-(void)movementDidOccur:(CGPoint)movement
{
    if (body!=nil)
    {
        float maxRevs = maxRevsSec*(MAX_WHEEL_LENGTH/(ccpDistance(start, end)));
        float maxMotorSpeed = (M_PI*2)*maxRevs;
        
        if (abs(body->GetAngularVelocity()) < maxMotorSpeed || [self acc:-movement.y isOppositeToVel:body->GetAngularVelocity()])
        {
            body->ApplyTorque(body->GetMass()*-movement.y*torque);
        }
    }
}

-(BOOL)acc:(float)acc isOppositeToVel:(float) vel
{
    if ((acc < 0 && vel > 0) || (acc > 0 && vel < 0))
    {
        return YES;
    }
    return NO;
}

-(void)highlightMe
{
    [super highlightMe];
    [MotorHub setColor:highlightedColor];
}

-(void)unHighlightMe
{
    [super unHighlightMe];
    [MotorHub setColor:originalColor];
}

-(BOOL)shouldRemoveFromAccelerationArray
{
    return isReadyForRemoval;
}

@end
