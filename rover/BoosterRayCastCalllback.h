//
//  BoosterRayCastCalllback.h
//  rover
//
//  Created by David Campbell on 7/3/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//
#import "Box2D.h"
#import "GameObject.h"
#import "Booster.h"

typedef std::vector<b2Fixture*> VectorFixtures;

#ifndef rover_BoosterRayCastCalllback_h
#define rover_BoosterRayCastCalllback_h


class BoosterRayCastcallback : public b2RayCastCallback
{
public:
    VectorFixtures fixtures;
    Vector2dVector points;
    
    BoosterRayCastcallback(){}
    
    float32 ReportFixture(b2Fixture* fixture, const b2Vec2& point, const b2Vec2& normal, float32 fraction)
    {
        GameObject *object = (GameObject*)fixture->GetBody()->GetUserData();
        if (!object){return 1.0f;}
        
        if (object.gameObjectType == kGroundType || object.gameObjectType == kBreakableGroundType)
        {
            fixtures.push_back(fixture);
            points.push_back(point);
        }
        return 1.0f;
    }
};

#endif
