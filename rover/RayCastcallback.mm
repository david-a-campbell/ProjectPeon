//
//  RayCastcallback.cpp
//  rover
//
//  Created by David Campbell on 3/11/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#include "RayCastcallback.h"
#import "PlayerCart.h"
#import "GameObject.h"
#import "Box2DHelpers.h"

CartPart *part;
BOOL foundForeGroundPart;

RayCastcallback::RayCastcallback(CartPart *p)
{
    part = p;
    outFixtureList = NULL;
}

float32 RayCastcallback::ReportFixture(b2Fixture* fixture, const b2Vec2& point, const b2Vec2& normal, float32 fraction)
{
    GameObject *gameObj = (GameObject*)fixture->GetBody()->GetUserData();
    CartPart *cartPart = (CartPart*)fixture->GetUserData();
    
    if (gameObj.gameObjectType != kPlayerCartType || fixture->IsSensor() || cartPart.gameObjectType == kMotorPartType || cartPart.gameObjectType == kMotor50PartType)
    {
        return 1.0f;
    }
    if (fixture->GetFilterData().categoryBits == kCollideNoneCat)
    {
        return 1.0f;
    }
    if (![cartPart isInForeground] && [part isInForeground])
    {
        return 1.0f;
    }
    
    b2Fixture* search = outFixtureList;
    while (search)
    {
        if (search == fixture)
        {
            return 1.0f;
        }
        search = search->punkNextFixture;
    }
    
    fixture->punkNextFixture = outFixtureList;
    outFixtureList = fixture;
    
    if(cartPart.isInForeground)
    {
        [part setIsInForeground:YES];
        part.categoryBits = kLayer3Cat;
        part.maskBits = kCollideAllMask;
    }
    
    return 1.0f;
}
