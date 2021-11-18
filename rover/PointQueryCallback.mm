//
//  PointQueryCallback.cpp
//  rover
//
//  Created by David Campbell on 3/11/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#include "PointQueryCallback.h"
#import "Box2DHelpers.h"

CartPart *partp;
b2Vec2 pointToTest;
BOOL foundFGpart;

PointQueryCallback::PointQueryCallback(CartPart *p, const b2Vec2& point)
{
    partp = p;
    pointToTest = point;
    outputFixtureList = NULL;
}

bool PointQueryCallback::ReportFixture(b2Fixture* fixture)
{
    GameObject *gameObj = (GameObject*)fixture->GetBody()->GetUserData();
    CartPart *cartPart = (CartPart*)fixture->GetUserData();
    
    if (partp == cartPart || gameObj.gameObjectType != kPlayerCartType || fixture->IsSensor() || cartPart.gameObjectType == kMotorPartType || cartPart.gameObjectType == kMotor50PartType)
    {
        return true;
    }
    if (fixture->GetFilterData().categoryBits == kCollideNoneCat)
    {
        return true;
    }
    if (![cartPart isInForeground] && [partp isInForeground])
    {
        return true;
    }
    
    //sometimes the point will catch inside the bounding box but outside the shape so do an extra test
    if (!fixture->TestPoint(pointToTest)) 
    {
        return true;
    }
    

    b2Fixture* search = outputFixtureList;
    while (search)
    {
        if (search == fixture)
        {
            return true;
        }
        search = search->punkNextFixture;
    }
    
    
    fixture->punkNextFixture = outputFixtureList;
    outputFixtureList = fixture;
    
    if(cartPart.isInForeground)
    {
        [partp setIsInForeground:YES];
        partp.categoryBits = kLayer3Cat;
        partp.maskBits = kCollideAllMask;
    }
    
    return true;
} 