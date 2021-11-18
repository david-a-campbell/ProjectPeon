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
