#ifndef PEON_PHYSICS_STEP_H
#define PEON_PHYSICS_STEP_H

#include "libs/Box2D/Box2D.h"

static inline void PeonStepPhysics(b2World *world, float frameTime)
{
    // Preserve the game's 2x simulation speed, with two smaller constraint solves.
    const bool autoClearForces = world->GetAutoClearForces();
    world->SetAutoClearForces(false);
    for (int step = 0; step < 2; ++step)
        world->Step(frameTime, 10, 8);
    if (autoClearForces)
        world->ClearForces();
    world->SetAutoClearForces(autoClearForces);
}

#endif
