//
//  Box2DHelpers.h
//  SpaceViking
//
//  Created by Ray Wenderlich on 3/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Box2D.h"
#import "Motor.h"
#import "CommonProtocols.h"
#include <vector>

typedef std::vector<b2Vec2> Vector2dVector;
typedef std::vector<b2ContactEdge*> VectorContactEdge;
typedef std::vector<b2Body*> VectorB2Body;

bool isBodyCollidingWithObjectType(b2Body *body, 
                                   GameObjectType objectType);

int numberOfObjectTypeCollidingWithBody(b2Body *body, GameObjectType objectType);
bool doesBodyHaveFixtures(b2Body *body);
void processBody(CartPart *part, b2Shape *shape);
float pixelsToMeterRatio();
void cleanupBodies(b2World *world);
void setupShocks(b2Fixture *oldFix, b2Fixture *newFix);
void setupSwivels(b2Body *oldBody, b2Body *newBody);

bool findIntersectionOfFixtures(b2Fixture* fA, b2Fixture* fB, Vector2dVector &outputVertices);
b2Vec2 ComputeCentroid(Vector2dVector vs, float& area);
void edgesCollidingWithObjectType(b2Body *body, GameObjectType objectType, VectorContactEdge& vce);

