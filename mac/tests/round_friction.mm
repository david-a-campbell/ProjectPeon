#import "ContactListner.h"
#include <cassert>
#include <cmath>
#include <cstdio>

BOOL PeonKeyDown(unsigned short code) __asm("_PeonKeyDown");
BOOL PeonKeyDown(unsigned short code) { return NO; }

// Contact classification needs part identity, without sprite assets or a renderer.
@interface FrictionPart : Box2DSprite
@end
@implementation FrictionPart
-(void)handleContact:(b2Contact *)contact withOldManifold:(const b2Manifold *)old otherFixture:(b2Fixture *)fixture {}
-(void)handleContact:(b2Contact *)contact withImpulse:(const b2ContactImpulse *)impulse otherFixture:(b2Fixture *)fixture {}
@end

static FrictionPart *part(GameObjectType type)
{
    FrictionPart *object = [FrictionPart alloc];
    object.gameObjectType = type;
    return object;
}

static void checkPair(GameObjectType typeA, GameObjectType typeB, bool increased, bool missingMetadata = false)
{
    b2World world(b2Vec2_zero);
    ContactListner listener;
    world.SetContactListener(&listener);
    b2BodyDef definition;
    b2Body *a = world.CreateBody(&definition);
    definition.type = b2_dynamicBody;
    definition.position.Set(1.95f, 0);
    b2Body *b = world.CreateBody(&definition);
    b2CircleShape shape;
    shape.m_radius = 1;
    b2FixtureDef fixture;
    fixture.shape = &shape;
    fixture.density = 1;
    fixture.friction = 2;
    b2Fixture *fa = a->CreateFixture(&fixture);
    fixture.friction = 0.5f;
    b2Fixture *fb = b->CreateFixture(&fixture);
    FrictionPart *pa = part(typeA), *pb = part(typeB);
    FrictionPart *cart = part(kPlayerCartType);
    // Composite cart bodies cannot identify individual wheel/bar fixtures.
    a->SetUserData(cart); b->SetUserData(cart);
    fa->SetUserData(missingMetadata ? NULL : pa);
    fb->SetUserData(pb);
    for (int frame = 0; frame < 20; ++frame) {
        b->SetTransform(b2Vec2(1.95f, 0), 0);
        b->SetLinearVelocity(b2Vec2_zero);
        world.Step(1.0f / 60, 10, 8);
        b2Contact *contact = world.GetContactList();
        assert(contact && contact->IsTouching());
        assert(std::fabs(contact->GetFriction() - (increased ? 2.0f : 1.0f)) < 0.00001f);
        assert(fa->GetFriction() == 2 && fb->GetFriction() == 0.5f);
        assert(contact->GetRestitution() == 0);
    }
    world.SetContactListener(NULL);
    // These test identities deliberately skip sprite initialization; the process owns them.
}

int main()
{
    @autoreleasepool {
        const GameObjectType round[] = {kWheelPartType, kMotorPartType, kMotor50PartType};
        const GameObjectType other[] = {kBarPartType, kBoosterPartType, kBooster50PartType,
            kGroundType, kBreakableGroundType, kRockType, kBridgeType, kPlayerCartType};
        for (GameObjectType a : round) {
            for (GameObjectType b : round) checkPair(a, b, true);
            for (GameObjectType b : other) {
                checkPair(a, b, false);
                checkPair(b, a, false);
            }
        }
        checkPair(kBarPartType, kGroundType, false);
        checkPair(kWheelPartType, kMotorPartType, false, true);
        std::puts("Wheel/circle pairs gain 2x friction; terrain, other parts, fixture materials, restitution, repeated solves, and missing metadata: PASS");
    }
}
