//
//  SpriteTrigger.m
//  rover
//
//  Created by David Campbell on 7/12/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "SpriteTrigger.h"
#import "Box2DHelpers.h"

@implementation SpriteTrigger

-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld
{
    if (self = [super init])
    {
        [self setGameObjectType:kSpriteTrigger];
        canSendNotifications = YES;
        world = theWorld;
        [self setupBodyWithDict:dict];
        [self setupFixtureWithDict:dict];
        triggerId = [[dict valueForKey:@"TriggerID"] intValue];
    }
    return self;
}

-(void)setupBodyWithDict:(id)dict
{
    float x = [[dict valueForKey:@"x"] floatValue];
    float y = [[dict valueForKey:@"y"] floatValue];
    [self setPosition:ccp(x, y)];
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    body = world->CreateBody(&bodyDef);
    body->SetUserData(self);
}

-(void)setupFixtureWithDict:(id)dict
{
    b2FixtureDef fixtureDef;
    fixtureDef.filter.maskBits = kDontCollideWithGround;
    fixtureDef.isSensor = true;
    NSString *pointsString = [dict valueForKey:@"polygonPoints"];
    [self polygonatePoints:pointsString ontoBody:body withFixtureDef:fixtureDef offset:CGSizeMake(0, 0) flipY:YES forcePolygonation:YES];
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    if (canSendNotifications)
    {
        [self checkForCart];
    }
}

-(void)checkForCart
{
    b2ContactEdge* edge = body->GetContactList();
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching())
        {
            b2Fixture* fixtureB = contact->GetFixtureB();
            b2Body *bodyB = fixtureB->GetBody();
            Box2DSprite *fixtureBSprite = (Box2DSprite*)fixtureB->GetUserData();
            Box2DSprite *bodyBSprite = (Box2DSprite*)bodyB->GetUserData();
            
            if (fixtureBSprite != nil && fixtureBSprite != self)
            {
                if (bodyBSprite.gameObjectType != kPlayerCartType)
                {
                    return;
                }
                
                NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:[NSNumber numberWithInt:triggerId] forKey:@"TriggerID"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TRIGGER_SPRITE object:self userInfo:userInfo];
                canSendNotifications = NO;
                break;
            }
        }
        edge = edge->next;
    }
}

-(void)resetTrigger
{
    canSendNotifications = YES;
}


@end
