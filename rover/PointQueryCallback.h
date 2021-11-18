//
//  PointQueryCallback.h
//  rover
//
//  Created by David Campbell on 3/11/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2D.h"
#import "CartPart.h"
#ifndef PointQueryCallback_H
#define PointQueryCallback_H

class PointQueryCallback : public b2QueryCallback
{
public:
    PointQueryCallback(CartPart *part, const b2Vec2& point);
    bool ReportFixture(b2Fixture* fixture);
    b2Fixture *outputFixtureList;
};
#endif
