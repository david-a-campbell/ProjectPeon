//
//  Box2DHelpers.mm
//  SpaceViking
//
//  Created by Ray Wenderlich on 3/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Box2DHelpers.h"
#import "Box2DSprite.h"
#import "CartPart.h"
#import "Bar.h"
#import "Booster.h"
#import "RayCastcallback.h"
#import "PointQueryCallback.h"
#import "DeleteAble.h"
#import "ShockAbsorber.h"
#import "PlayerCart.h"


float pixelsToMeterRatio()
{
	return (32.0f);
}

//will always return true if the body passed in is of type objecttype
bool isBodyCollidingWithObjectType(b2Body *body, GameObjectType objectType) 
{
    b2ContactEdge* edge = body->GetContactList();
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching()) 
        {        
            b2Fixture* fixtureA = contact->GetFixtureA();
            b2Fixture* fixtureB = contact->GetFixtureB();
            b2Body *bodyA = fixtureA->GetBody();
            b2Body *bodyB = fixtureB->GetBody();
            Box2DSprite *spriteA = 
            (Box2DSprite *) bodyA->GetUserData();
            Box2DSprite *spriteB = 
            (Box2DSprite *) bodyB->GetUserData();
            if ((spriteA != NULL && 
                 spriteA.gameObjectType == objectType) ||
                (spriteB != NULL && 
                 spriteB.gameObjectType == objectType)) {
                    return true;
                }        
        }
        edge = edge->next;
    }    
    return false;
}

void edgesCollidingWithObjectType(b2Body *body, GameObjectType objectType, VectorContactEdge& vce)
{
    b2ContactEdge* edge = body->GetContactList();
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching())
        {
            b2Fixture* fixtureA = contact->GetFixtureA();
            b2Body *bodyA = fixtureA->GetBody();
            Box2DSprite *spriteA = (Box2DSprite *) bodyA->GetUserData();
            if ((spriteA != NULL && spriteA.gameObjectType == objectType))
            {
                vce.push_back(edge);
            }
        }
        edge = edge->next;
    }
}

int numberOfObjectTypeCollidingWithBody(b2Body *body, GameObjectType objectType)
{
    CCArray *countArray = [CCArray array];
    b2ContactEdge* edge = body->GetContactList();
    while (edge)
    {
        b2Contact* contact = edge->contact;
        if (contact->IsTouching()) 
        {        
            b2Fixture* fixtureA = contact->GetFixtureA();
            b2Fixture* fixtureB = contact->GetFixtureB();
            b2Body *bodyA = fixtureA->GetBody();
            b2Body *bodyB = fixtureB->GetBody();
            Box2DSprite *spriteA = 
            (Box2DSprite *) bodyA->GetUserData();
            Box2DSprite *spriteB = 
            (Box2DSprite *) bodyB->GetUserData();
            if (spriteA != NULL && spriteA.gameObjectType == objectType)
            {
                if (![countArray containsObject:spriteA]) {
                    [countArray addObject:spriteA];
                }
            }else if(spriteB != NULL && spriteB.gameObjectType == objectType)
            {
                if (![countArray containsObject:spriteB]) {
                    [countArray addObject:spriteB];
                }
            }        
        }
        edge = edge->next;
    }    
    return [countArray count];    
}


bool doesBodyHaveFixtures(b2Body *body)
{
    if (body->GetFixtureList())
    {
        return true;
    }
    return false;
}

void processBody(CartPart *part, b2Shape *shape)
{
        //Setup body
        b2BodyDef bd;
        bd.position = b2Vec2(part.start.x/pixelsToMeterRatio(), part.start.y/pixelsToMeterRatio());
        if (part.gameObjectType == kBarPartType)
        {
            CGPoint mid = ccpMidpoint(part.start, part.end);
            bd.position = b2Vec2(mid.x/pixelsToMeterRatio(), mid.y/pixelsToMeterRatio());
        }
        bd.bullet = YES;
        bd.type = b2_staticBody;
        part.body = part.world->CreateBody(&bd);
        part.body->SetUserData(part.cart);
    
        b2Fixture *found = NULL;
    
        switch (part.gameObjectType)
        {
            case kBarPartType:
            {
                b2PolygonShape *poly = (b2PolygonShape*)shape;
                CGPoint mid = ccpMidpoint(part.start, part.end);
                b2Vec2 b2Mid(mid.x/pixelsToMeterRatio(), mid.y/pixelsToMeterRatio());
                RayCastcallback callback(part);
                //store the vertices because they can become modified by the callback
                b2Vec2 vertices[4];
                for (int x = 0; x<4; ++x)
                    vertices[x] = poly->m_vertices[x]+b2Mid;
                for (int x = 0; x<4; ++x)
                    part.world->RayCast(&callback, vertices[x], vertices[(x+1)%4]);

                found = callback.outFixtureList;

                if (!found)
                {
                    //Do a point callback if we dont find anything from the ray cast
                    b2AABB aabb;
                    b2Vec2 delta = b2Vec2(1.0/pixelsToMeterRatio(), 1.0/pixelsToMeterRatio());
                    aabb.lowerBound = b2Mid - delta;
                    aabb.upperBound = b2Mid + delta;
                    PointQueryCallback pCallback(part, b2Mid);
                    part.world->QueryAABB(&pCallback, aabb);
                    found = pCallback.outputFixtureList;
                }
            }break;
            case kBoosterPartType:
            case kBooster50PartType:
            {
                b2PolygonShape *poly = (b2PolygonShape*)shape;
                b2Vec2 b2Mid(part.start.x/pixelsToMeterRatio(), part.start.y/pixelsToMeterRatio());
                RayCastcallback callback(part);
                //store the vertices because they can become modified by the callback
                b2Vec2 vertices[8];
                for (int x = 0; x<8; ++x)
                    vertices[x] = poly->m_vertices[x]+b2Mid;
                for (int x = 0; x<8; ++x)
                    part.world->RayCast(&callback, vertices[x], vertices[(x+1)%8]);
                
                found = callback.outFixtureList;
                
                if (!found)
                {
                    //Do a point callback if we dont find anything from the ray cast
                    b2AABB aabb;
                    b2Vec2 delta = b2Vec2(1.0/pixelsToMeterRatio(), 1.0/pixelsToMeterRatio());
                    aabb.lowerBound = b2Mid - delta;
                    aabb.upperBound = b2Mid + delta;
                    PointQueryCallback pCallback(part, b2Mid);
                    part.world->QueryAABB(&pCallback, aabb);
                    found = pCallback.outputFixtureList;
                }
            }break;
            case kWheelPartType:
            {
                b2CircleShape *circle = (b2CircleShape*)shape;
                CGPoint cgCenter = ccp(part.start.x/pixelsToMeterRatio(), part.start.y/pixelsToMeterRatio());
                int n = 360;
                CGPoint p1 = ccpRotateByAngle(ccp(cgCenter.x+circle->m_radius,cgCenter.y), cgCenter, CC_DEGREES_TO_RADIANS(1.0));
                RayCastcallback callback(part);
                for (int x = 0; x<n; ++x)
                {
                    b2Vec2 b1 = b2Vec2(p1.x, p1.y);
                    part.world->RayCast(&callback, b2Vec2(cgCenter.x, cgCenter.y), b1);
                    p1 = ccpRotateByAngle(p1, cgCenter, CC_DEGREES_TO_RADIANS(1.0));
                }
                
                found = callback.outFixtureList;
                
                if(!found)
                {
                    //Do a point callback if we dont find anything from the ray cast
                    b2AABB aabb;
                    b2Vec2 delta = b2Vec2(1.0/pixelsToMeterRatio(), 1.0/pixelsToMeterRatio());
                    aabb.lowerBound = b2Vec2(cgCenter.x, cgCenter.y) - delta;
                    aabb.upperBound = b2Vec2(cgCenter.x, cgCenter.y) + delta;
                    PointQueryCallback pCallback(part, b2Vec2(cgCenter.x, cgCenter.y));
                    part.world->QueryAABB(&pCallback, aabb);
                    found = pCallback.outputFixtureList;
                    
                }
            }break;
            default:
                return;
                break;
        }
    
    
        //Setup Fixture
        b2FixtureDef fixtureDef = [part createFixtureDef];
        fixtureDef.shape = shape;
        part.fixture = part.body->CreateFixture(&fixtureDef);
        part.fixture->SetUserData(part);
    
        while (found)
        {
            CartPart *foundPart = (CartPart*)found->GetUserData();
            if (!foundPart)
            {
                found = found->punkNextFixture;
                continue;
            }
            if ([part isInForeground] && ![foundPart isInForeground])
            {
                found = found->punkNextFixture;
                continue;
            }
            
            b2Body *oldBody = foundPart.body;
            b2Fixture *oldFixtures = oldBody->GetFixtureList();
            while (oldFixtures)
            {
                if (oldFixtures->IsSensor() || oldFixtures->GetFilterData().categoryBits == kCollideNoneCat)
                {
                    oldFixtures = oldFixtures->GetNext();
                    continue;
                }
                
                if (oldFixtures->GetUserData() == nil){break;}
                CartPart *secondaryPart = (CartPart*)oldFixtures->GetUserData();
                b2FixtureDef fixDef = [secondaryPart createFixtureDef];
                
                if (part.gameObjectType == kBarPartType)
                {
                    b2PolygonShape *partShape = [(Bar*)secondaryPart createShapeForCenter:part.body->GetWorldCenter()];
                    fixDef.shape = partShape;
                }
                if (part.gameObjectType == kBoosterPartType || part.gameObjectType == kBooster50PartType)
                {
                    b2PolygonShape *partShape = [(Booster*)secondaryPart createShapeForCenter:part.body->GetWorldCenter()];
                    fixDef.shape = partShape;
                }
                if([[part class] isSubclassOfClass:[Wheel class]])
                {
                    b2CircleShape *partShape = [(Wheel*)secondaryPart createShapeForCenter:part.body->GetWorldCenter()];
                    fixDef.shape = partShape;
                }
                
                secondaryPart.fixture = part.body->CreateFixture(&fixDef);
                secondaryPart.fixture->SetUserData(secondaryPart);
                secondaryPart.body = part.body;
                delete fixDef.shape;
                
                //Recreate swivel on newBody
                if([[secondaryPart class] isSubclassOfClass:[Wheel class]])
                {
                    [(Wheel*)secondaryPart createBuoyancyFixture];
                    if ([(Wheel*)secondaryPart swivelBody])
                    {
                        [(Wheel*)secondaryPart setupWheelJointWithBody:[(Wheel*)secondaryPart swivelBody]];
                    }
                }
                //Recreate sensor on bar
                if (secondaryPart.gameObjectType == kBarPartType)
                {
                    [(Bar*)secondaryPart createSensor];
                }
                
                //Move shocks and pivots to new fixture
                setupShocks(oldFixtures, secondaryPart.fixture);
                
                oldFixtures->SetUserData(nil);
                oldFixtures = oldFixtures->GetNext();
            }
            
            setupSwivels(oldBody, part.body);
            oldBody->SetUserData([[DeleteAble alloc] init]);
            found = found->punkNextFixture;
        }
    
        cleanupBodies(part.world);
}

void cleanupBodies(b2World *world)
{
    b2Body *worldBodies = world->GetBodyList();
    while(worldBodies)
    {
        NSObject *trash = (NSObject*)worldBodies->GetUserData();
        if([[trash class] isSubclassOfClass:[DeleteAble class]])
        {
            b2Body *temp = worldBodies;
            worldBodies = worldBodies->GetNext();
            b2Fixture *aFixture = temp->GetFixtureList();
            
            while (aFixture)
            {
                b2Fixture *tempFix = aFixture;
                aFixture = aFixture->GetNext();
                tempFix->SetUserData(nil);
                temp->DestroyFixture(tempFix);
            }
            
            temp->SetUserData(nil);
            world->DestroyBody(temp);
            [trash release];
            continue;
        }
        worldBodies = worldBodies->GetNext();
    }
}

void setupShocks(b2Fixture *oldFix, b2Fixture *newFix)
{
    NSMutableArray *shocksToDelete = [NSMutableArray array];
    
   b2JointEdge *jointEdge = oldFix->GetBody()->GetJointList();
    while (jointEdge)
    {
        b2Joint *joint = jointEdge->joint;
        if (joint->GetUserData() != NULL)
        {
            CartPart* part = (CartPart*)joint->GetUserData();
            //Reconnect Shocks
            if ([[part class] isSubclassOfClass:[ShockAbsorber class]])
            {
                ShockAbsorber *shock = (ShockAbsorber*)part;
                if ([shock fixture1] == oldFix || [shock fixture2] == oldFix)
                {
                    BOOL succsess = [shock moveJointFrom:oldFix to:newFix];
                    if (!succsess)
                    {
                        [shocksToDelete addObject:shock];
                    }
                }
            }
        }
        jointEdge = jointEdge->next;
    }
    
    for (ShockAbsorber *shock in shocksToDelete)
    {
        [shock.cart deleteCartPart:shock];
    }
}

void setupSwivels(b2Body *oldBody, b2Body *newBody)
{
    b2JointEdge *jointEdge = oldBody->GetJointList();
    while (jointEdge)
    {
        b2Joint *joint = jointEdge->joint;
        if (joint->GetUserData() != NULL)
        {
            CartPart* part = (CartPart*)joint->GetUserData();
            //Reconnect Wheels and Motors
            if ([[part class] isSubclassOfClass:[Wheel class]])
            {
                Wheel *wheel = (Wheel*)part;
                if (oldBody == joint->GetBodyA() || oldBody == joint->GetBodyB())
                {
                    if (newBody != wheel.body)
                    {
                        [wheel setupWheelJointWithBody:newBody];
                    }
                }
            }
        }
        jointEdge = jointEdge->next;
    }
}

//
//  BUOYANCY STUFF
//


bool inside(b2Vec2 cp1, b2Vec2 cp2, b2Vec2 p) {
    return (cp2.x-cp1.x)*(p.y-cp1.y) > (cp2.y-cp1.y)*(p.x-cp1.x);
}

b2Vec2 intersection(b2Vec2 cp1, b2Vec2 cp2, b2Vec2 s, b2Vec2 e) {
    b2Vec2 dc( cp1.x - cp2.x, cp1.y - cp2.y );
    b2Vec2 dp( s.x - e.x, s.y - e.y );
    float n1 = cp1.x * cp2.y - cp1.y * cp2.x;
    float n2 = s.x * e.y - s.y * e.x;
    float n3 = 1.0 / (dc.x * dp.y - dc.y * dp.x);
    return b2Vec2( (n1*dp.x - n2*dc.x) * n3, (n1*dp.y - n2*dc.y) * n3);
}

//http://rosettacode.org/wiki/Sutherland-Hodgman_polygon_clipping#JavaScript
//Note that this only works when fB is a convex polygon, but we know all
//fixtures in Box2D are convex, so that will not be a problem
bool findIntersectionOfFixtures(b2Fixture* fA, b2Fixture* fB, Vector2dVector &outputVertices)
{
    //currently this only handles polygon vs polygon
    if ( fA->GetShape()->GetType() != b2Shape::e_polygon ||
        fB->GetShape()->GetType() != b2Shape::e_polygon )
        return false;
    
    b2PolygonShape* polyA = (b2PolygonShape*)fA->GetShape();
    b2PolygonShape* polyB = (b2PolygonShape*)fB->GetShape();
    
    //fill subject polygon from fixtureA polygon
    for (int i = 0; i < polyA->GetVertexCount(); i++)
        outputVertices.push_back( fA->GetBody()->GetWorldPoint( polyA->GetVertex(i) ) );
    
    //fill clip polygon from fixtureB polygon
    Vector2dVector clipPolygon;
    for (int i = 0; i < polyB->GetVertexCount(); i++)
        clipPolygon.push_back( fB->GetBody()->GetWorldPoint( polyB->GetVertex(i) ) );
    
    b2Vec2 cp1 = clipPolygon[clipPolygon.size()-1];
    for (int j = 0; j < clipPolygon.size(); j++) {
        b2Vec2 cp2 = clipPolygon[j];
        if ( outputVertices.empty() )
            return false;
        Vector2dVector inputList = outputVertices;
        outputVertices.clear();
        b2Vec2 s = inputList[inputList.size() - 1]; //last on the input list
        for (int i = 0; i < inputList.size(); i++) {
            b2Vec2 e = inputList[i];
            if (inside(cp1, cp2, e)) {
                if (!inside(cp1, cp2, s)) {
                    outputVertices.push_back( intersection(cp1, cp2, s, e) );
                }
                outputVertices.push_back(e);
            }
            else if (inside(cp1, cp2, s)) {
                outputVertices.push_back( intersection(cp1, cp2, s, e) );
            }
            s = e;
        }
        cp1 = cp2;
    }
    
    return !outputVertices.empty();
}

//Taken from b2PolygonShape.cpp
b2Vec2 ComputeCentroid(Vector2dVector vs, float& area)
{
    int count = (int)vs.size();
    b2Assert(count >= 3);
    
    b2Vec2 c;
    c.Set(0.0f, 0.0f);
    area = 0.0f;
    
    // pRef is the reference point for forming triangles.
    // Its location doesnt change the result (except for rounding error).
    b2Vec2 pRef(0.0f, 0.0f);
    
    const float32 inv3 = 1.0f / 3.0f;
    
    for (int32 i = 0; i < count; ++i)
    {
        // Triangle vertices.
        b2Vec2 p1 = pRef;
        b2Vec2 p2 = vs[i];
        b2Vec2 p3 = i + 1 < count ? vs[i+1] : vs[0];
        
        b2Vec2 e1 = p2 - p1;
        b2Vec2 e2 = p3 - p1;
        
        float32 D = b2Cross(e1, e2);
        
        float32 triangleArea = 0.5f * D;
        area += triangleArea;
        
        // Area weighted centroid
        c += triangleArea * inv3 * (p1 + p2 + p3);
    }
    
    // Centroid
    if (area > b2_epsilon)
        c *= 1.0f / area;
    else
        area = 0;
    return c;
}



