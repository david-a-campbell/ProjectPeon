//
//  RayCastcallback.h
//  rover
//
//  Created by David Campbell on 3/10/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2D.h"
#import "CartPart.h"

#ifndef RayCastcallback_H
#define RayCastcallback_H

class RayCastcallback : public b2RayCastCallback
{
public:
    float32 ReportFixture(b2Fixture* fixture, const b2Vec2& point, const b2Vec2& normal, float32 fraction);
    RayCastcallback(CartPart *part);
    b2Fixture *outFixtureList;
};
#endif