//
//  Pod.m
//  rover
//
//  Created by David Campbell on 7/21/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Pod.h"
#import "Box2DHelpers.h"
#import "Ground.h"
#import "BoosterRayCastCalllback.h"

@implementation Pod

-(id)initWithWorld:(b2World *)theWorld atLocation:(CGPoint)location andLayer:(CCLayer*)layer
{
    if ((self = [super init])) {
        soundEffectKey =  0;
        parentLayer = layer;
        [self setGameObjectType:kPodType];
        world = theWorld;
        [self setupImages];
        [self setPosition:location];
        [self createBodyAtLocation:location];
        [self setupSensors];
        [self setupEdges];
        [self setupRamp];
        characterState = kStateAwaitingCart;
        shouldFireBooster = NO;
        [self scheduleUpdate];
    }
    return self;
}

-(void)dealloc
{
    podRamp = nil;
    [super dealloc];
}

-(void)resetPod
{
    [[GameManager sharedGameManager] stopSoundEffect:soundEffectKey];
    shouldFireBooster = NO;
    [blastEmitter stopSystem];
    body->SetUserData(nil);
    world->DestroyBody(body);
    [self setPosition:originalPosition];
    [self createBodyAtLocation:originalPosition];
    [self setupEdges];
    [self openDoor];
    [self setupRamp];
}

-(void)setPosition:(CGPoint)position
{
    [podBackground setPosition:ccp(position.x-backGroundOffset.x, position.y-backGroundOffset.y)];
    [blastEmitter setPosition:ccp(position.x, position.y - 1075.5f)];
    [super setPosition:position];
}

-(void)setupImages
{
    [self setDisplayFrame:[[CCSprite spriteWithFile:@"podForeground.png"] displayFrame]];
    [self setScale:2*SCREEN_SCALE];
    podDoor = [CCSprite spriteWithFile:@"podDoor.png"];
    [podDoor setScale:2*SCREEN_SCALE];
    [podDoor setAnchorPoint:ccp(0, 0)];
    [podDoor setPosition:ccp(157.0f/(2*SCREEN_SCALE), 333.0f/(2*SCREEN_SCALE))];
    [podDoor setOpacity:0];
    [self addChild:podDoor z:-1];
    podBackground = [CCSprite spriteWithFile:@"podBackground.png"];
    [podBackground setScale:2*SCREEN_SCALE];
    backGroundOffset = ccp(0, -258.0f/2.0f);
    [parentLayer addChild:podBackground z:-500];
    
    blastEmitter = [CCParticleSystemQuad particleWithFile:@"PodRocket.plist"];
    [[blastEmitter texture] setAliasTexParameters];
    [blastEmitter setPositionType:kCCPositionTypeGrouped];
    [blastEmitter setScale:2];
    [parentLayer addChild:blastEmitter z:-501];
    [blastEmitter stopSystem];
}

- (void)createBodyAtLocation:(CGPoint)location
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    bd.bullet = true;
    bd.position = b2Vec2(location.x/pixelsToMeterRatio(), location.y/pixelsToMeterRatio());
    body = world->CreateBody(&bd);
    body->SetUserData(self);
    originalPosition = location;
}

-(void)setupSensors
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    bd.position = b2Vec2(originalPosition.x/pixelsToMeterRatio(), originalPosition.y/pixelsToMeterRatio());
    counterBody = world->CreateBody(&bd);
    cartTouchBody = world->CreateBody(&bd);
    
    b2FixtureDef fixtureDef;
    fixtureDef.isSensor = true;
    b2PolygonShape shape;
    float xOffset = 1010.75;
    float yOffset = 1245;
    b2Vec2 verts[] = {
        b2Vec2((171.0f -xOffset) /pixelsToMeterRatio(), (348.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1854.0f -xOffset) /pixelsToMeterRatio(), (348.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1679.0f -xOffset) /pixelsToMeterRatio(), (1861.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1467.5f -xOffset) /pixelsToMeterRatio(), (2146.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1011.5f -xOffset) /pixelsToMeterRatio(), (2475.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((555.0f -xOffset) /pixelsToMeterRatio(), (2146.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((344.0f -xOffset) /pixelsToMeterRatio(), (1863.5f -yOffset)/pixelsToMeterRatio()),
    };
    shape.Set(verts, 7);
    fixtureDef.shape = &shape;
    counterBody->CreateFixture(&fixtureDef);
    
    
    b2PolygonShape shape2;
    b2Vec2 verts2[] = {
        b2Vec2((1413.0f -xOffset) /pixelsToMeterRatio(), (348.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1854.0f -xOffset) /pixelsToMeterRatio(), (348.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1735.0f -xOffset) /pixelsToMeterRatio(), (1542.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1679.0f -xOffset) /pixelsToMeterRatio(), (1858.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1565.5f -xOffset) /pixelsToMeterRatio(), (2032.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1413.0f -xOffset) /pixelsToMeterRatio(), (2186.0f -yOffset)/pixelsToMeterRatio())
    };
    shape2.Set(verts2, 6);
    fixtureDef.shape = &shape2;
    cartTouchBody->CreateFixture(&fixtureDef);
}

-(void)setupEdges
{
    b2EdgeShape shipShape;      
    b2FixtureDef shipFixtureDef;
    shipFixtureDef.shape = &shipShape;
    shipFixtureDef.filter.categoryBits = kPodCat;
    shipFixtureDef.filter.maskBits = kPodMask;
    
    float xOffset = 1010.75;
    float yOffset = 1245;
    
    b2Vec2 verts[] = {
        b2Vec2((238.0f -xOffset) /pixelsToMeterRatio(), (1239.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((279.0f -xOffset) /pixelsToMeterRatio(), (1551.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((333.5f -xOffset) /pixelsToMeterRatio(), (1864.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((431.0f -xOffset) /pixelsToMeterRatio(), (2046.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((590.5f -xOffset) /pixelsToMeterRatio(), (2186.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((771.0f -xOffset) /pixelsToMeterRatio(), (2334.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1010.5f -xOffset) /pixelsToMeterRatio(), (2489.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1236.5f -xOffset) /pixelsToMeterRatio(), (2344.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1433.0f -xOffset) /pixelsToMeterRatio(), (2186.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1579.0f -xOffset) /pixelsToMeterRatio(), (2034.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1688.5f -xOffset) /pixelsToMeterRatio(), (1865.5f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1742.5f -xOffset) /pixelsToMeterRatio(), (1556.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1790.5f -xOffset) /pixelsToMeterRatio(), (1175.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1865.0f -xOffset) /pixelsToMeterRatio(), (348.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((158.0f -xOffset) /pixelsToMeterRatio(), (348.0f -yOffset)/pixelsToMeterRatio())
    };
    
    for (int x = 0; x < 14; x++)
    {
        shipShape.Set(verts[x], verts[x+1]);
        body->CreateFixture(&shipFixtureDef);
    }
    
    doorVector1 = verts[0];
    doorVector2 = verts[14];
    
    //setup base
    b2PolygonShape base;
    b2FixtureDef baseFixtureDef;
    baseFixtureDef.shape = &base;
    baseFixtureDef.filter.maskBits = kCollideWithNone;
    baseFixtureDef.density = 5000.0;
    baseFixtureDef.friction = 1.0;
    baseFixtureDef.restitution = 0.2;
    
    b2Vec2 verts2[] = {
        b2Vec2((418.0f -xOffset) /pixelsToMeterRatio(), (122.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((354.0f -xOffset) /pixelsToMeterRatio(), (228.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1671.0f -xOffset) /pixelsToMeterRatio(), (228.0f -yOffset)/pixelsToMeterRatio()),
        b2Vec2((1607.0f -xOffset) /pixelsToMeterRatio(), (122.0f -yOffset)/pixelsToMeterRatio())
    };
    
    base.Set(verts2, 4);
    body->CreateFixture(&baseFixtureDef);
}

-(void)closeDoor
{
    b2EdgeShape shipShape;      
    b2FixtureDef shipFixtureDef;
    shipFixtureDef.shape = &shipShape;
    shipShape.Set(doorVector1, doorVector2);
    door = body->CreateFixture(&shipFixtureDef);
    
    CGPoint finalPos = [podDoor position];
    [podDoor setScaleX:0];
    [podDoor setPosition:ccp([podDoor position].x+324.5/(2*SCREEN_SCALE), [podDoor position].y)];
    [podDoor setOpacity:255];
    [podDoor runAction:[CCSpawn actions:[CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1], [CCMoveTo actionWithDuration:0.5 position:finalPos],nil]];
    [podRamp runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.7], [CCCallFunc actionWithTarget:podRamp selector:@selector(retractRamp)], nil]];
    characterState = kStateDoorClosed;
}

-(void)openDoor
{
    [podDoor setPosition:ccp(157.0f/(2*SCREEN_SCALE), 333.0f/(2*SCREEN_SCALE))];
    [podDoor setOpacity:0];
    characterState = kStateAwaitingCart;
}

-(void)setupRamp
{
    if (podRamp != nil)
    {
        [podRamp removeFromParentAndCleanup:YES];
        podRamp = nil;
    }
    
    CGPoint offset = ccp([self boundingBox].size.width/2.0 - 168, [self boundingBox].size.height/2.0 - 349);
    CGPoint location = ccp([self position].x - offset.x, [self position].y - offset.y);
    podRamp = [[PodRamp alloc] initWithWorld:world atLocation:location withBody:body];
    [podRamp setDelegate:self];
    [parentLayer addChild:podRamp z:[self zOrder]-1];
    [podRamp release];
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    if (shouldFireBooster)
    {
        float mass = fabsf((body->GetMass()+cartWeight)*world->GetGravity().y)*0.1;
        body->ApplyLinearImpulse(b2Vec2(0, mass), body->GetWorldCenter());
    }
    
    if (characterState == kStateDoorClosed) {
        return;
    }
    
    if(isBodyCollidingWithObjectType(cartTouchBody, kPlayerCartType))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LEVEL_COMPLETE object:nil];
        [self closeDoor];
    }
}

-(void)liftOffWithWeight:(float)weight
{
    cartWeight = weight;
    body->SetType(b2_dynamicBody);
    body->SetFixedRotation(true);
    shouldFireBooster = YES;
}

-(void)rampRetracted
{
    [blastEmitter resetSystem];
    [[GameManager sharedGameManager] stopSoundEffect:soundEffectKey];
    soundEffectKey = [self playSoundEffect:@"mothership.mp3"];
}

-(int)countPeons
{
    return numberOfObjectTypeCollidingWithBody(counterBody, kThingyBasic);
}

-(void)update:(ccTime)delta
{
    if (![blastEmitter active]){return;}
    BoosterRayCastcallback callback;
    
    b2Vec2 origin = b2Vec2(_position.x/pixelsToMeterRatio(), _position.y/pixelsToMeterRatio() -1055.0f/pixelsToMeterRatio());
    b2Vec2 final = b2Vec2(origin.x,origin.y-1300.0f/pixelsToMeterRatio());
    world->RayCast(&callback, origin, final);
    
    if (!callback.points.size()){return;}
    
    b2Vec2 closest = callback.points[0];
    int index = 0;
    int indexToUse = 0;
    for (Vector2dVector::iterator it = callback.points.begin(); it != callback.points.end(); ++it)
    {
        b2Vec2 nextPoint = *it;
        if (b2Distance(origin, closest) > b2Distance(origin, nextPoint))
        {
            closest = nextPoint;
            indexToUse = index;
        }
        index++;
    }
    [self createDustForGround:callback.fixtures[indexToUse] point:closest];
}

-(void)sceneEnd
{
    [[GameManager sharedGameManager] stopSoundEffect:soundEffectKey];
}

-(void)createDustForGround:(b2Fixture *)groundFix point:(b2Vec2)point
{
    Box2DSprite *otherSprite = (Box2DSprite*)groundFix->GetBody()->GetUserData();
    
    if ([self probabilityWithPercent:DUST_PROBABILITY])
    {
        CGPoint position = ccp(point.x*pixelsToMeterRatio(), point.y*pixelsToMeterRatio());
        for (NSString *emitterName in [(Ground*)otherSprite dustEmitters])
        {
            emitterName = [NSString stringWithFormat:@"%@_Pod%@", emitterName, @".plist"];
            
            CCParticleSystemQuad *dustEmitter = [CCParticleSystemQuad particleWithFile:emitterName];
            [dustEmitter setAngle:40];
            [dustEmitter setTangentialAccel:500];
            [[dustEmitter texture] setAliasTexParameters];
            [dustEmitter setAutoRemoveOnFinish:YES];
            [dustEmitter setPositionType:kCCPositionTypeGrouped];
            [dustEmitter setPosition:position];
            [[self parent] addChild:dustEmitter z:GroundZ-1];
            [dustEmitter resetSystem];
            
            CCParticleSystemQuad *dustEmitter2 = [CCParticleSystemQuad particleWithFile:emitterName];
            [dustEmitter2 setAngle:180-40];
            [dustEmitter2 setTangentialAccel:-500];
            [[dustEmitter2 texture] setAliasTexParameters];
            [dustEmitter2 setAutoRemoveOnFinish:YES];
            [dustEmitter2 setPositionType:kCCPositionTypeGrouped];
            [dustEmitter2 setPosition:position];
            [[self parent] addChild:dustEmitter2 z:GroundZ-1];
            [dustEmitter2 resetSystem];
        }
    }
}

@end
