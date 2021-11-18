//
//  Elevator.m
//  rover
//
//  Created by David Campbell on 6/23/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Elevator.h"
#import "PlayerCart.h"
#import "Box2DHelpers.h"

@implementation Elevator

-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld
{
    if ((self = [super init]))
    {
        world = theWorld;
        [self setGameObjectType:kElevatorType];
        [self setCharacterState:kStateMovementStopped];
        triggerId = [[dict valueForKey:@"TriggerID"] intValue];
        direction = [[NSString stringWithFormat:@"%@",[dict valueForKey:@"Direction"]] retain];
        time = [[dict valueForKey:@"Time"] floatValue];
        stopTime1 = [[dict valueForKey:@"StopTime1"] floatValue];
        stopTime2 = [[dict valueForKey:@"StopTime2"] floatValue];
        x = [[dict valueForKey:@"x"] floatValue];
        y = [[dict valueForKey:@"y"] floatValue];
        [self setupImage:dict];
        plankSize = CGSizeMake([self boundingBox].size.width, [self boundingBox].size.height);
        height = [[dict valueForKey:@"height"] floatValue];
        width = [[dict valueForKey:@"width"] floatValue];
        reversed = [[dict valueForKey:@"Reverse"] boolValue]; 
        sPosition = [self startPosition];
        fPosition = [self finalPosition];
        [self createElevator];
        if (triggerId != 0)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerMovement:) name:NOTIFICATION_TRIGGER_SPRITE object:nil];
        }else
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginMovement) name:NOTIFICATION_BEGIN_GAMEPLAY object:nil];
        }
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unscheduleAllSelectors];
    [direction release];
    direction = nil;
    [super dealloc];
}

-(void)setupImage:(id)dict
{
    [self setDisplayFrame:[[CCSprite spriteWithFile:[dict valueForKey:@"Texture"]] displayFrame]];
    [self setScale:2*SCREEN_SCALE];
}

-(void)createElevator
{
    b2Vec2 location;
    if (!reversed) {
        [self setPosition:sPosition];
        location = b2Vec2(sPosition.x/pixelsToMeterRatio(), sPosition.y/pixelsToMeterRatio());
    }else {
        [self setPosition:fPosition];
        location = b2Vec2(fPosition.x/pixelsToMeterRatio(), fPosition.y/pixelsToMeterRatio());
    }

    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.fixedRotation = true;
    bodyDef.gravityScale = 0;
    bodyDef.position = location;
    
    body = world->CreateBody(&bodyDef);
    body->SetUserData(self);
    
    bodyDef.type = b2_staticBody;
    anchorBody = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;   
    b2Vec2 boxCenter = b2Vec2(0,0);
    shape.SetAsBox(plankSize.width/2/pixelsToMeterRatio(), plankSize.height/2/pixelsToMeterRatio(), boxCenter, 0); 
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.friction = 1.0;
    fixtureDef.restitution = 0.1;
    fixtureDef.density = 20000;
    fixtureDef.filter.categoryBits = kGroundCat;
    fixtureDef.filter.maskBits = kDontCollideWithGround;
    body->CreateFixture(&fixtureDef);
    
    b2PrismaticJointDef jointDef;
    CGPoint vector = ccp(fPosition.x-sPosition.x, fPosition.y-sPosition.y);
    vector = ccpNormalize(vector);
    jointDef.Initialize(body, anchorBody, anchorBody->GetWorldCenter(), b2Vec2(vector.x, vector.y));
    world->CreateJoint(&jointDef);
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects 
{
    if (characterState == kStateAwaitingCart || characterState == kStateMovementStopped) {
        body->SetLinearVelocity(b2Vec2(0,0));
        return;
    }
    
    if (characterState == kStateMovingBack || characterState == kStateMovingTo)
    {
        elapsedTime+=deltaTime;
    }
    
    switch (elevatorDirection) {
        case kDirectionVertical:
        case kDirectionDiagonalUp:
            if (([self position].y >= fPosition.y) && characterState != kStateMovingBack) 
            {
                nextState = kStateMovingBack;
                [self changeState:kStateAwaitingCart];
            }else if(([self position].y <= sPosition.y) && characterState != kStateMovingTo)
            {
                nextState = kStateMovingTo;
                [self changeState:kStateAwaitingCart];
            }
            break;
        case kDirectionHorizontal:
            if (([self position].x >= fPosition.x) && characterState != kStateMovingBack) 
            {
                nextState = kStateMovingBack;
                [self changeState:kStateAwaitingCart];
            }else if(([self position].x <= sPosition.x) && characterState != kStateMovingTo)
            {
                nextState = kStateMovingTo;
                [self changeState:kStateAwaitingCart];
            }
            break;
        case kDirectionDiagonalDown:
            if (([self position].y <= fPosition.y) && characterState != kStateMovingBack) 
            {
                nextState = kStateMovingBack;
                [self changeState:kStateAwaitingCart];
            }else if(([self position].y >= sPosition.y) && characterState != kStateMovingTo)
            {
                nextState = kStateMovingTo;
                [self changeState:kStateAwaitingCart];
            }  
            break;
        default:
            break;
    }
    
    if (characterState == kStateMovingBack || characterState == kStateMovingTo)
    {
        if (elapsedTime > time+1)
        {
            [self reverseDirection];
        }
    }
    
    if (characterState != kStateAwaitingCart)
    {
        if ([self isVelocityLessThanDesired])
        {
            body->ApplyForce([self impulse], body->GetWorldCenter());
        }
    }
}

-(void)changeState:(CharacterStates)newState
{
    if (characterState == newState) {
        return;
    }
    
    elapsedTime = 0;
    [self setCharacterState:newState];
    
    if (newState == kStateMovementStopped)
    {
        [self stopAllActions];
    }
    
    if (newState == kStateAwaitingCart)
    {
        body->SetLinearVelocity(b2Vec2(0,0));
        if (nextState == kStateMovingBack)
        {
            [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:stopTime2], [CCCallFunc actionWithTarget:self selector:@selector(resumeMove)],nil]];
        }else
        {
            [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:stopTime1], [CCCallFunc actionWithTarget:self selector:@selector(resumeMove)],nil]];
        }
    }
    
    if (newState == kStateMovingBack || newState == kStateMovingTo)
    {
        body->SetType(b2_dynamicBody);
    }else
    {
        body->SetType(b2_staticBody);
    }
}

-(void)reverseDirection
{
    if ([self characterState] == kStateMovingTo)
    {
        nextState = kStateMovingTo;
        [self changeState:kStateMovingBack];
    }else {
        nextState = kStateMovingBack;
        [self changeState:kStateMovingTo];
    }
}

-(void)beginMovement
{
    if (!reversed) {
        nextState = kStateMovingTo;
    }else {
        nextState = kStateMovingBack;
    }
    [self changeState:kStateAwaitingCart];  
}

-(void)resetElevator
{
    [self changeState:kStateMovementStopped];
    if (!reversed) {
        body->SetTransform(b2Vec2(sPosition.x/pixelsToMeterRatio(), sPosition.y/pixelsToMeterRatio()), body->GetAngle());
    }else {
        body->SetTransform(b2Vec2(fPosition.x/pixelsToMeterRatio(), fPosition.y/pixelsToMeterRatio()), body->GetAngle());
    }

}

-(void)resumeMove
{
    [self changeState:nextState];
}

-(CGPoint)startPosition
{
    if ([[direction lowercaseString] isEqualToString:@"vertical"]) 
    {
        elevatorDirection = kDirectionVertical;
        return ccp(x+width/2, y+plankSize.height/2);
    }else if([[direction lowercaseString] isEqualToString:@"horizontal"])
    {
        elevatorDirection = kDirectionHorizontal;
        return ccp(x+plankSize.width/2, y+height-plankSize.height/2);
    }else if ([[direction lowercaseString] isEqualToString:@"diagonalup"])
    {
        elevatorDirection = kDirectionDiagonalUp;
        return ccp(x+plankSize.width/2, y+plankSize.height/2);       
    }else if ([[direction lowercaseString] isEqualToString:@"diagonaldown"])
    {
        elevatorDirection = kDirectionDiagonalDown;
        return ccp(x+plankSize.width/2, y+height-plankSize.height/2);       
    }
    return ccp(0, 0);
}

-(CGPoint)finalPosition
{
    if ([[direction lowercaseString] isEqualToString:@"vertical"]) 
    {
        return ccp(x+width/2, y+height-plankSize.height/2);
    }else if([[direction lowercaseString] isEqualToString:@"horizontal"])
    {
        return ccp(x+width-plankSize.width/2, y+height-plankSize.height/2);
    }else if ([[direction lowercaseString] isEqualToString:@"diagonalup"])
    {
        return ccp(x+width-plankSize.width/2, y+height-plankSize.height/2);       
    }else if ([[direction lowercaseString] isEqualToString:@"diagonaldown"])
    {
        return ccp(x+width-plankSize.width/2, y+plankSize.height/2);     
    }
    return ccp(0, 0);
}

-(CGPoint)travelDistance
{
    float xDist = fabsf(sPosition.x - fPosition.x)/pixelsToMeterRatio();
    float yDist = fabsf(sPosition.y - fPosition.y)/pixelsToMeterRatio();
    return ccp(xDist, yDist);
}

-(BOOL)isVelocityLessThanDesired
{
    b2Vec2 vel = body->GetLinearVelocity();
    b2Vec2 desired = [self desiredVelocity];
    
    BOOL xIsLess = desired.x>0? vel.x*2<desired.x : vel.x*2>desired.x;
    BOOL yIsLess = desired.y>0? vel.y*2<desired.y : vel.y*2>desired.y;

    return (xIsLess || yIsLess);
}

-(b2Vec2)desiredVelocity
{
    b2Vec2 desiredVel = b2Vec2(([self travelDistance].x/time), ([self travelDistance].y/time));
    
    if (elevatorDirection == kDirectionDiagonalDown) {
        desiredVel = b2Vec2(desiredVel.x, -1*desiredVel.y);
    }
    
    if (characterState == kStateMovingBack) {
        desiredVel = b2Vec2(-1*desiredVel.x, -1*desiredVel.y);
    }
    
    return b2Vec2(desiredVel.x, desiredVel.y);
}

-(b2Vec2)impulse
{
    b2Vec2 vel = body->GetLinearVelocity();
    return b2Vec2(([self desiredVelocity].x -vel.x*2)*body->GetMass()*5, ([self desiredVelocity].y -vel.y*2)*body->GetMass()*5);
}

-(void)triggerMovement:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    int tID= [[userInfo objectForKey:@"TriggerID"] intValue];
    if (triggerId == tID)
    {
        [self beginMovement];
    }
}

@end
