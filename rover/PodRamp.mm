//
//  PodRamp.m
//  rover
//
//  Created by David Campbell on 7/21/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "PodRamp.h"
#import "Box2DHelpers.h"

@implementation PodRamp
@synthesize delegate;

-(id)initWithWorld:(b2World *)theWorld atLocation:(CGPoint)location withBody:(b2Body*)passedBody
{
    if ((self = [super init]))
    {
        world = theWorld;
        [self setupImages];
        [self createLimitBlock:location];
        [self createBodyAtLocation:location];
        [self setupPhysics:passedBody];
    }
    return self;
}

-(void)setupImages
{
    podRamp1 = [CCSprite spriteWithFile:@"podRamp1.png"];
    podRamp2 = [CCSprite spriteWithFile:@"podRamp2.png"];
    [self addChild:podRamp1];
    [self addChild:podRamp2];
    [self setScale:2*SCREEN_SCALE];
}

- (void)createBodyAtLocation:(CGPoint)location
{
    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    bd.bullet = true;
    bd.position = b2Vec2(location.x/pixelsToMeterRatio(), location.y/pixelsToMeterRatio());
    body = world->CreateBody(&bd);
    body->SetUserData(self);
    originalPosition = location;    
}

- (void)createLimitBlock:(CGPoint)location
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    bd.bullet = false;
    bd.position = b2Vec2((location.x-1507.50/2.0f)/pixelsToMeterRatio(), (location.y+60.0)/pixelsToMeterRatio());
    limitBody = world->CreateBody(&bd);
    
    b2FixtureDef fixtureDef;
    fixtureDef.filter.categoryBits = kRampCat;
    fixtureDef.filter.maskBits = kRampOnlyMask;
    fixtureDef.friction = 1.0;
    fixtureDef.restitution = 0.0;
    fixtureDef.density = 100000.0;
    
    b2PolygonShape shape;
    shape.SetAsBox(20.0/pixelsToMeterRatio(), 20.0/pixelsToMeterRatio());
    fixtureDef.shape = &shape;
    limitBody->CreateFixture(&fixtureDef);
}

-(void)setupPhysics:(b2Body*)passedBody
{    
    b2FixtureDef rampFixtureDef;
    rampFixtureDef.filter.categoryBits = kRampCat;
    rampFixtureDef.filter.maskBits = kRampMask;
    rampFixtureDef.friction = 1.0;
    rampFixtureDef.restitution = 0.0;
    rampFixtureDef.density = 100000.0;
    
    NSString *points = @"7,110 1,112 0,118 13,126 40,134 732,129 1508,134 1503 119 1493,104 744,74 732,78 724,85 714,86";
    [self polygonatePoints:points ontoBody:body withFixtureDef:rampFixtureDef offset:CGSizeMake(1507.50, 134) flipY:NO forcePolygonation:YES];
    
    b2DistanceJointDef jointDef;
    jointDef.collideConnected = false;
    jointDef.frequencyHz = 20.0f;
    jointDef.dampingRatio = 0.001f;
    jointDef.Initialize(body, passedBody, body->GetPosition(), body->GetPosition());
    world->CreateJoint(&jointDef);
}

-(void)retractRamp
{
    float rotation = CC_RADIANS_TO_DEGREES(body->GetAngle() * -1);
    [self removeRampPhysics];
    [self runAction:[CCRotateBy actionWithDuration:1 angle:-rotation]];
    [podRamp1 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1], [CCMoveBy actionWithDuration:1.5 position:ccp(1600/(2*SCREEN_SCALE), 0)],nil]];
    [podRamp2 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:2], [CCMoveBy actionWithDuration:1 position:ccp(800/(2*SCREEN_SCALE), 0)], [CCCallFunc actionWithTarget:self selector:@selector(makeInvisible)], [CCCallFunc actionWithTarget:delegate selector:@selector(rampRetracted)],nil]];
}

-(void)makeInvisible
{
    [podRamp1 setOpacity:0];
    [podRamp2 setOpacity:0];
}

-(void)removeRampPhysics
{
    body->SetUserData(nil);
    world->DestroyBody(body);
    world->DestroyBody(limitBody);
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
