//
//  DeletePartQueryCallback.h
//  rover
//
//  Created by David Campbell on 3/18/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//
#import "Box2D.h"
#import "GameObject.h"
#import "Wheel.h"

class DeletePartQueryCallback : public b2QueryCallback
{
public:
    b2Vec2 pointToTest;
    b2Fixture *fixtureFound;
    b2Fixture *fixtureNotToReport;
    
    DeletePartQueryCallback(const b2Vec2& point, b2Fixture *notFix) {
        pointToTest = point;
        fixtureFound = nil;
        fixtureNotToReport = notFix;
    }
    
    bool ReportFixture(b2Fixture *fixture) 
    {
        GameObject *object = (GameObject*)fixture->GetBody()->GetUserData();
        CartPart *cartPart = (CartPart*)fixture->GetUserData();
        
        if (cartPart.gameObjectType == kShockPartType)
        {
            object = cartPart.cart;
        }
        if (fixture->GetFilterData().categoryBits == kCollideNoneCat)
        {
            return true;
        }
        if (fixture->IsSensor() && [[cartPart class] isSubclassOfClass:[Wheel class]])
        {
            return true;
        }
        
        if (object.gameObjectType == kPlayerCartType && fixture != fixtureNotToReport) 
        {
            if (fixture->TestPoint(pointToTest)) 
            {
                if (fixture->IsSensor() && cartPart.gameObjectType == kBarPartType)
                {
                    fixture = cartPart.fixture;
                }
                fixtureFound = fixture;
                return false;
            }
        }        
        return true;
    }        
};