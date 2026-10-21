#include "PeonPhysicsStep.h"
#include <cassert>
#include <cmath>
#include <cstdio>
#include <initializer_list>

static void advance(b2World &world, float dt, bool substeps)
{
    if (substeps) PeonStepPhysics(&world, dt);
    else world.Step(2 * dt, 10, 8);
}

static float compression(int shape, float dt, bool substeps)
{
    b2World world(b2Vec2(0, -10));
    b2BodyDef groundDef;
    b2Body *ground = world.CreateBody(&groundDef);
    b2PolygonShape floor;
    floor.SetAsBox(100, 0.1f, b2Vec2(0, -0.1f), 0);
    ground->CreateFixture(&floor, 0);

    b2BodyDef definition;
    definition.type = b2_dynamicBody;
    definition.position.Set(0, 0.25f);
    b2CircleShape circle;
    circle.m_radius = 0.25f;
    const float spacing = shape == 0 ? 1.5f : 0.45f;
    b2Body *wheels[2];
    for (int side = 0; side < 2; ++side) {
        definition.position.x = side == 0 ? -spacing : spacing;
        wheels[side] = world.CreateBody(&definition);
        b2FixtureDef wheelFixture;
        wheelFixture.shape = &circle;
        wheelFixture.density = 2500;
        wheelFixture.filter.groupIndex = -1;
        wheels[side]->CreateFixture(&wheelFixture);
    }

    definition.position.x = 0;
    b2Body *backing = world.CreateBody(&definition);
    b2PolygonShape rectangle;
    rectangle.SetAsBox(shape == 0 ? 2.0f : 0.6f, shape == 0 ? 0.12f : 0.25f);
    circle.m_radius = 0.9f;
    b2FixtureDef fixture;
    fixture.shape = shape == 2 ? static_cast<b2Shape *>(&circle) : &rectangle;
    fixture.density = shape == 0 ? 16000 : 2500;
    // Isolate load on the pivot from direct backing-to-ground contact.
    fixture.filter.maskBits = 0;
    backing->CreateFixture(&fixture);
    b2Joint *joints[2];
    for (int side = 0; side < 2; ++side) {
        b2RevoluteJointDef hinge;
        hinge.Initialize(backing, wheels[side], wheels[side]->GetPosition());
        joints[side] = world.CreateJoint(&hinge);
    }

    float error = 0;
    const int frames = static_cast<int>(4 / dt);
    for (int frame = 0; frame < frames; ++frame) {
        backing->ApplyForce(b2Vec2(0, -80 * backing->GetMass()), backing->GetWorldCenter());
        advance(world, dt, substeps);
        for (b2Joint *joint : joints)
            error += (joint->GetAnchorA() - joint->GetAnchorB()).Length() / 2;
    }
    return error / frames;
}

static void checkPower(bool autoClear)
{
    b2World original(b2Vec2_zero), changed(b2Vec2_zero);
    original.SetAutoClearForces(autoClear);
    changed.SetAutoClearForces(autoClear);
    b2BodyDef definition;
    definition.type = b2_dynamicBody;
    b2Body *a = original.CreateBody(&definition), *b = changed.CreateBody(&definition);
    b2CircleShape circle;
    circle.m_radius = 1;
    a->CreateFixture(&circle, 1); b->CreateFixture(&circle, 1);
    for (int frame = 0; frame < 60; ++frame) {
        for (b2Body *body : {a, b}) {
            body->ApplyForce(b2Vec2(3, 0), body->GetWorldCenter());
            body->ApplyTorque(0.5f);
            body->ApplyLinearImpulse(b2Vec2(0, 0.02f), body->GetWorldCenter());
        }
        advance(original, 1.0f / 60, false);
        advance(changed, 1.0f / 60, true);
        assert((a->GetLinearVelocity() - b->GetLinearVelocity()).Length() < 0.001f);
        assert(std::fabs(a->GetAngularVelocity() - b->GetAngularVelocity()) < 0.001f);
        assert(changed.GetAutoClearForces() == autoClear);
    }
}

static void checkRotation()
{
    b2World world(b2Vec2_zero);
    b2BodyDef definition;
    b2Body *backing = world.CreateBody(&definition);
    definition.type = b2_dynamicBody;
    b2Body *wheel = world.CreateBody(&definition);
    b2CircleShape circle;
    circle.m_radius = 1;
    wheel->CreateFixture(&circle, 1);
    b2RevoluteJointDef hinge;
    hinge.Initialize(backing, wheel, b2Vec2_zero);
    b2Joint *joint = world.CreateJoint(&hinge);
    for (int frame = 0; frame < 60; ++frame) {
        wheel->ApplyTorque(1);
        PeonStepPhysics(&world, 1.0f / 60);
    }
    assert(wheel->GetAngle() > 0.1f);
    assert((joint->GetAnchorA() - joint->GetAnchorB()).Length() < 0.005f);
}

int main()
{
    const char *names[] = {"bar", "booster", "circle"};
    for (int shape = 0; shape < 3; ++shape) {
        for (int fps : {30, 60, 120}) {
            const float before = compression(shape, 1.0f / fps, false);
            const float after = compression(shape, 1.0f / fps, true);
            std::printf("%s at %d FPS: mean pivot separation %.6f -> %.6f m\n", names[shape], fps, before, after);
            assert(std::isfinite(after));
            assert(after < 0.005f);
            // Ignore differences below two micrometres from float roundoff.
            assert(after <= b2Max(before * 0.8f, 0.000002f));
        }
    }
    checkPower(true);
    checkPower(false);
    checkRotation();
    std::puts("Compression, motor force, boost impulse, force clearing, and free rotation: PASS");
}
