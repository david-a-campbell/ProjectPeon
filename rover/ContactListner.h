//
//  ContactListner.h
//  rover
//
//  Created by David Campbell on 7/2/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Box2D.h"
#import "Box2DSprite.h"

#ifndef rover_ContactListner_h
#define rover_ContactListner_h

class ContactListner : public b2ContactListener
{
#if defined(PROJECTPEON_MAC) || defined(PROJECTPEON_IOS)
    bool isWheelOrCircle(b2Fixture *fixture, Box2DSprite *part)
    {
        if (fixture->IsSensor() || ![part isKindOfClass:[Box2DSprite class]])
            return false;
        return part.gameObjectType == kWheelPartType ||
               part.gameObjectType == kMotorPartType ||
               part.gameObjectType == kMotor50PartType;
    }
#endif
public:
    ContactListner(){}
    
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
	{
        Box2DSprite *objectA = (Box2DSprite*)contact->GetFixtureA()->GetUserData();
        Box2DSprite *objectB = (Box2DSprite*)contact->GetFixtureB()->GetUserData();
        
        if(objectA !=nil && [[objectA class] isSubclassOfClass:[Box2DSprite class]])
        {
            [objectA handleContact:contact withOldManifold:oldManifold otherFixture:contact->GetFixtureB()];
        }
        if(objectB !=nil && [[objectB class] isSubclassOfClass:[Box2DSprite class]])
        {
            [objectB handleContact:contact withOldManifold:oldManifold otherFixture:contact->GetFixtureA()];
        }

#if defined(PROJECTPEON_MAC) || defined(PROJECTPEON_IOS)
        b2Fixture *fixtureA = contact->GetFixtureA();
        b2Fixture *fixtureB = contact->GetFixtureB();
        if (isWheelOrCircle(fixtureA, objectA) && isWheelOrCircle(fixtureB, objectB))
        {
            // Override only this pair; fixture friction still governs all other contacts.
            // Recompute from the fixtures so repeated solves do not compound the boost.
            contact->SetFriction(2.0f * b2MixFriction(fixtureA->GetFriction(), fixtureB->GetFriction()));
        }
#endif
        
        if (contact->GetFixtureA()->GetFilterData().categoryBits == kCollideNoneCat ||
            contact->GetFixtureB()->GetFilterData().categoryBits == kCollideNoneCat)
        {
            contact->SetEnabled(false);
        }
	}
    
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse)
	{
        Box2DSprite *objectA = (Box2DSprite*)contact->GetFixtureA()->GetUserData();
        Box2DSprite *objectB = (Box2DSprite*)contact->GetFixtureB()->GetUserData();
        
        if(!handleContact(contact, impulse, objectA, contact->GetFixtureB()))
        {
            objectA = (Box2DSprite*)contact->GetFixtureA()->GetBody()->GetUserData();
            handleContact(contact, impulse, objectA, contact->GetFixtureB());
        }
        
        if(!handleContact(contact, impulse, objectB, contact->GetFixtureA()))
        {
            objectB = (Box2DSprite*)contact->GetFixtureB()->GetBody()->GetUserData();
            handleContact(contact, impulse, objectB, contact->GetFixtureA());
        }
	}
    
    BOOL handleContact(b2Contact* contact, const b2ContactImpulse* impulse, Box2DSprite* object, b2Fixture *otherFixture)
    {
        if(object !=nil && [[object class] isSubclassOfClass:[Box2DSprite class]])
        {
            [object handleContact:contact withImpulse:impulse otherFixture:otherFixture];
            return YES;
        }
        return NO;
    }
};

#endif
